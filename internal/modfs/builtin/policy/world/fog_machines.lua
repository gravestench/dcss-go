-- Vault fog markers become independent saved clocks. Terrain remains in the
-- level grid; each emitted cloud uses the ordinary cloud ECS owner.
local attribution = require("constants.cloud_attribution")
local component = require("constants.component")
local neighbors = require("constants.adjacent_cells")
local streams = require("constants.rng_streams")
local placement = require("policy.clouds.placement")

local machines = {}

local repeat_limit = 200

-- Use the saved fog stream for all choices made by a machine. The source
-- random_range helper averages several inclusive draws for cloud lifetime.
local function roll(ctx, minimum, maximum, count)
    local total = 0

    for _ = 1, count do
        total = total + minimum +
            ctx:random(streams.FOG_MACHINES, maximum - minimum + 1)
    end

    return math.floor(total / count)
end

-- A random walk may stay put. Source cloud.cc also samples that ninth
-- choice after choosing uniformly among eligible adjacent cells.
local function walk(ctx, state)
    local x = state.x
    local y = state.y

    for _ = 1, state.walk_dist do
        local choices = {}

        for _, offset in ipairs(neighbors) do
            local next_x = x + offset[1]
            local next_y = y + offset[2]

            if ctx:walkable(state.level_id, next_x, next_y) then
                choices[#choices + 1] = {
                    x = next_x,
                    y = next_y,
                }
            end
        end

        if #choices == 0 then
            break
        end

        local selected = ctx:random(streams.FOG_MACHINES,
            #choices + 1)

        if selected < #choices then
            x = choices[selected + 1].x
            y = choices[selected + 1].y
        end
    end

    return x, y
end

-- Shuffle each distance shell so source DES direction order cannot favor
-- one side of a fog source. This does not consult player line of sight.
local function shuffle(ctx, shell)
    for index = #shell, 2, -1 do
        local other = ctx:random(streams.FOG_MACHINES, index) + 1

        shell[index], shell[other] = shell[other], shell[index]
    end
end

-- A cloud remains registered with the normal cloud field, which owns its
-- lifetime, spread, replacement rule, opacity, and damage attribution.
local function place_cell(ctx, state, x, y, spread)
    local power = roll(ctx, state.pow_min, state.pow_max,
        state.pow_rolls)
    local options = {
        kill_category = attribution.OTHER,
        killer_type = attribution.MISC,
        exclusion_radius = state.exclusion_radius,
    }

    if spread >= 0 then
        options.spread_rate = spread
    end

    return placement.place(ctx, state.kind_id, nil,
        state.level_id, x, y, power * 10, options)
end

-- Expand through nonsolid cells, spending the selected size on candidates.
-- An existing cloud may reject replacement, as it does in source Crawl.
local function area(ctx, state, x, y, size, spread)
    local shell = {
        { x = x, y = y },
    }
    local seen = {
        [x .. ":" .. y] = true,
    }
    local attempted = 0

    while #shell > 0 and attempted < size do
        shuffle(ctx, shell)
        local next_shell = {}

        for _, cell in ipairs(shell) do
            if attempted < size then
                place_cell(ctx, state, cell.x, cell.y, spread)
                attempted = attempted + 1
            end

            for _, offset in ipairs(neighbors) do
                local next_x = cell.x + offset[1]
                local next_y = cell.y + offset[2]
                local key = next_x .. ":" .. next_y

                if not seen[key] then
                    seen[key] = true

                    if ctx:walkable(state.level_id, next_x, next_y) then
                        next_shell[#next_shell + 1] = {
                            x = next_x,
                            y = next_y,
                        }
                    end
                end
            end
        end

        shell = next_shell
    end
end

-- Source buildup is measured in turn-event ticks, which are aut in the
-- triggerer. Cap the increment without allowing a saved clock to overflow.
local function built_amount(amount, time, elapsed)
    return math.floor(amount * math.min(elapsed, time) / time)
end

-- One trigger emits the area selected by current size and spread buildup.
local function emit(ctx, state)
    local x, y = walk(ctx, state)
    local size_gain = built_amount(state.size_buildup_amnt,
        state.size_buildup_time, state.buildup_aut)
    local spread_gain = built_amount(state.spread_buildup_amnt,
        state.spread_buildup_time, state.buildup_aut)
    local size = roll(ctx, state.size_min + size_gain,
        state.size_max + size_gain, 1)
    local spread = state.spread_rate + spread_gain

    area(ctx, state, x, y, size, math.min(spread, 100))
end

-- A level entry redraws its countdown and produces the authored opening
-- burst. Save restore never calls this policy, so loading does not reroll.
local function enter(ctx, state)
    state.countdown_aut = roll(ctx, state.delay_min,
        state.delay_max, 1)

    for _ = 1, state.start_clouds do
        emit(ctx, state)
    end
end

-- Spend one action on the prior floor; each crossed delay boundary emits
-- once. The source triggerer limits pathological tiny-delay repeats to 200.
local function advance(ctx, state, elapsed)
    state.buildup_aut = math.min(state.buildup_aut + elapsed,
        state.size_buildup_time)
    state.countdown_aut = state.countdown_aut - elapsed

    for _ = 1, repeat_limit do
        if state.countdown_aut > 0 then
            break
        end

        emit(ctx, state)
        state.countdown_aut = state.countdown_aut +
            roll(ctx, state.delay_min, state.delay_max, 1)
    end

    if state.countdown_aut <= 0 then
        state.countdown_aut = roll(ctx, state.delay_min,
            state.delay_max, 1)
    end
end

-- Read machine entities in ID order from Akara's query. One policy call
-- advances only the source floor and optionally enters a new destination.
function machines.advance(ctx, input)
    local source_id = input.source_level_id
    local destination_id = input.destination_level_id
    local elapsed = input.elapsed_aut or 0

    for _, entity in ipairs(ctx:query({ component.FOG_MACHINE })) do
        local state = ctx:get(entity, component.FOG_MACHINE)

        if state.level_id == source_id and elapsed > 0 then
            advance(ctx, state, elapsed)
        end

        if input.enter and state.level_id == destination_id then
            enter(ctx, state)
        end

        ctx:set(entity, component.FOG_MACHINE, state)
    end

    return {}
end

register.policy({
    id = "world.fog_machines",
    run = machines.advance,
})

return machines

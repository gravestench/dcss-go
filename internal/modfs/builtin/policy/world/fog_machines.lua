-- Vault fog markers become independent saved clocks. Terrain remains in the
-- level grid; each emitted cloud uses the ordinary cloud ECS owner.
local attribution = require("constants.cloud_attribution")
local component = require("constants.component")
local neighbors = require("constants.adjacent_cells")
local streams = require("constants.rng_streams")
local placement = require("policy.clouds.placement")
local channels = require("constants.message_channels")
local volcano = require("constants.volcano")

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
local function walk(ctx, state, start_x, start_y)
    local x = start_x
    local y = start_y

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
local function emit_at(ctx, state, source_x, source_y)
    local x, y = walk(ctx, state, source_x, source_y)
    local size_gain = built_amount(state.size_buildup_amnt,
        state.size_buildup_time, state.buildup_aut)
    local spread_gain = built_amount(state.spread_buildup_amnt,
        state.spread_buildup_time, state.buildup_aut)
    local size = roll(ctx, state.size_min + size_gain,
        state.size_max + size_gain, 1)
    local spread = state.spread_rate + spread_gain

    area(ctx, state, x, y, size, math.min(spread, 100))
end

-- A chained source marker places a separate cloud area at each authored
-- location, but all slave locations consume one master's saved clock.
local function emit(ctx, state)
    if #state.positions_x == 0 then
        emit_at(ctx, state, state.x, state.y)

        return
    end

    for index, x in ipairs(state.positions_x) do
        emit_at(ctx, state, x, state.positions_y[index])
    end
end

-- The source warning listener belongs to the machine, not to a cloud.
-- Large sources warn by smell regardless of sight. Small sources use the
-- source's circular twelve-cell test for both warning and firing text;
-- outside that radius they say nothing. A saved flag suppresses repeats.
local function warn(ctx, state, firing)
    if state.listener == "" then
        return
    end

    local player = ctx:get(ctx:player(), component.POSITION)

    if not player or player.level_id ~= state.level_id then
        return
    end

    local dx = player.x - state.x
    local dy = player.y - state.y
    local near = dx * dx + dy * dy <= 12 * 12 + 1

    if state.listener == volcano.SMALL_FOG_LISTENER then
        if near then
            local message = firing and volcano.ERUPTION_SMALL or
                volcano.ERUPTION_WARNING
            ctx:emit(channels.VAULT, message)
        end

        return
    end

    if not firing then
        ctx:emit(channels.VAULT, volcano.ERUPTION_WARNING)

        return
    end

    if ctx:visible(state.level_id, player.x, player.y,
        7, state.x, state.y) then
        ctx:emit(channels.VAULT, volcano.ERUPTION_NEAR)
    else
        ctx:emit(channels.VAULT, volcano.ERUPTION_DISTANT)
    end
end

-- A level entry redraws its countdown and produces the authored opening
-- burst. Save restore never calls this policy, so loading does not reroll.
local function enter(ctx, state)
    state.countdown_aut = roll(ctx, state.delay_min,
        state.delay_max, 1)
    state.warned = false

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

        warn(ctx, state, true)
        emit(ctx, state)
        state.countdown_aut = state.countdown_aut +
            roll(ctx, state.delay_min, state.delay_max, 1)
        state.warned = false
    end

    if state.countdown_aut <= 0 then
        state.countdown_aut = roll(ctx, state.delay_min,
            state.delay_max, 1)
    end

    if state.countdown_aut <= 30 and not state.warned then
        warn(ctx, state, false)
        state.warned = true
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

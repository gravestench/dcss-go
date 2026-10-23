-- Theory of operation: source markers identify cave doors and lava groups;
-- Akara stores only clocks, phase, and the subset still eligible to change.
-- The active floor's dense grid is the single owner of mutable terrain.
local attribution = require("constants.cloud_attribution")
local clouds = require("ids.clouds")
local component = require("constants.component")
local channels = require("constants.message_channels")
local neighbors = require("constants.adjacent_cells")
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local volcano = require("constants.volcano")

local events = {}

-- Draw the next inclusive source interval only when an event fires.
local function delay(ctx, minimum, maximum)
    return minimum + ctx:random(streams.VOLCANO_HAZARDS,
        maximum - minimum + 1)
end

-- Apply the source's small grey-smoke burst after the selected door becomes
-- a wall. A breadth-first shell includes open cells beyond the new wall.
local function smoke(ctx, level_id, x, y)
    local queue = {
        { x = x, y = y },
    }
    local seen = {
        [x .. ":" .. y] = true,
    }
    local placed = 0

    while #queue > 0 and placed < 10 do
        local next_ring = {}

        for _, cell in ipairs(queue) do
            if ctx:walkable(level_id, cell.x, cell.y) then
                local power = 1 + ctx:random(
                    streams.VOLCANO_HAZARDS, 6)
                local cloud = placement.place(ctx,
                    clouds.CLOUD_GREY_SMOKE, nil, level_id,
                    cell.x, cell.y, power * 10, {
                        kill_category = attribution.OTHER,
                        killer_type = attribution.MISC,
                        exclusion_radius = -1,
                    })

                if cloud then
                    placed = placed + 1
                end
            end

            for _, offset in ipairs(neighbors) do
                local next_x = cell.x + offset[1]
                local next_y = cell.y + offset[2]
                local key = next_x .. ":" .. next_y

                if not seen[key] and
                    ctx:walkable(level_id, next_x, next_y) then
                    seen[key] = true
                    next_ring[#next_ring + 1] = {
                        x = next_x,
                        y = next_y,
                    }
                end
            end
        end

        queue = next_ring
    end
end

-- Select exactly one remaining source doorway. Standing on it causes the
-- warning but leaves it eligible for a later tick, as in the source hook.
local function collapse(ctx, state, player)
    if #state.record_indices == 0 then
        state.countdown_aut = 0
        return
    end

    local selected = 1 + ctx:random(streams.VOLCANO_HAZARDS,
        #state.record_indices)
    local x = state.positions_x[selected]
    local y = state.positions_y[selected]

    if player.x == x and player.y == y then
        ctx:emit(channels.WARNING,
            "There is a rumble as the volcano erupts. The roof shakes.")
    else
        if ctx:visible(state.level_id, player.x, player.y,
            7, x, y) then
            ctx:emit(channels.WARNING,
                "The volcano erupts! Nearby, a roof collapses.")
        else
            ctx:emit(channels.WARNING,
                "There is a rumble as the volcano erupts. The roof shakes.")
        end

        ctx:set_cell(state.level_id, x, y,
            terrain.DNGN_STONE_WALL)
        ctx:set_cell_colour(state.level_id, x, y,
            volcano.COLLAPSE_WALL_COLOUR)
        smoke(ctx, state.level_id, x, y)
        table.remove(state.record_indices, selected)
        table.remove(state.positions_x, selected)
        table.remove(state.positions_y, selected)
    end

    if #state.record_indices > 0 then
        state.countdown_aut = state.countdown_aut +
            delay(ctx, volcano.COLLAPSE_MIN_AUT,
                volcano.COLLAPSE_MAX_AUT)
    else
        state.countdown_aut = 0
    end
end

-- Track whether a specific cell actually became lava. A player standing
-- on a marked cell blocks conversion, and hardening cannot invent a change
-- that never happened there.
local function converted(state, source_index)
    for index, saved in ipairs(state.converted_indices) do
        if saved == source_index then
            return index
        end
    end

    return nil
end

-- Even phases pour onto one group; phases 7–9 harden groups 6/4/2 in
-- reverse order. The player cell is left as it was on both transitions.
local function change_group(ctx, state, player, group, harden)
    for index, phase in ipairs(state.groups) do
        if phase == group then
            local source_index = state.record_indices[index]
            local x = state.positions_x[index]
            local y = state.positions_y[index]
            local prior = converted(state, source_index)

            if (player.x ~= x or player.y ~= y) and
                (not harden or prior) then
                ctx:set_cell(state.level_id, x, y,
                    harden and terrain.DNGN_FLOOR or
                        terrain.DNGN_LAVA)

                if harden then
                    table.remove(state.converted_indices, prior)
                elseif not prior then
                    state.converted_indices[
                        #state.converted_indices + 1] = source_index
                end
            end
        end
    end
end

-- Phase messages and terrain changes follow the authored nine-step order.
-- Nothing mutates when the clock has completed its last hardening step.
local function overflow(ctx, state, player)
    state.phase = state.phase + 1

    if state.phase == 1 then
        ctx:emit(channels.WARNING, "The ground shudders ominously.")
    elseif state.phase == 2 then
        ctx:emit(channels.WARNING, "In the distance, the volcano explodes " ..
            "with a roar! Lava spreads onto the path.")
        change_group(ctx, state, player, 2, false)
    elseif state.phase == 3 then
        ctx:emit(channels.WARNING,
            "The air is thick with the scent of sulphur.")
    elseif state.phase == 4 then
        ctx:emit(channels.WARNING,
            "There is another distant roar. More lava overflows!")
        change_group(ctx, state, player, 4, false)
    elseif state.phase == 5 then
        ctx:emit(channels.WARNING, "The ground moves violently!")
    elseif state.phase == 6 then
        ctx:emit(channels.WARNING, "The volcano erupts again! A thin layer " ..
            "of lava overflows to fill the cavern.")
        change_group(ctx, state, player, 6, false)
    elseif state.phase <= 9 then
        ctx:emit(channels.WARNING, "The ground shudders. Some of the lava " ..
            "has hardened enough to walk over!")
        change_group(ctx, state, player,
            (10 - state.phase) * 2, true)
    end

    if state.phase < 9 then
        state.countdown_aut = state.countdown_aut +
            delay(ctx, volcano.OVERFLOW_MIN_AUT,
                volcano.OVERFLOW_MAX_AUT)
    else
        state.countdown_aut = 0
    end
end

-- Advance cave then overflow in stable entity order on the one active
-- Volcano floor. Each crossed delay boundary fires once; long actions can
-- cross several boundaries without silently discarding events.
function events.advance(ctx, player, elapsed)
    for _, entity in ipairs(ctx:query({
        component.WORLD_VOLCANO_COLLAPSE,
    })) do
        local state = ctx:get(entity,
            component.WORLD_VOLCANO_COLLAPSE)

        if state.level_id == player.level_id and
            #state.record_indices > 0 then
            state.countdown_aut = state.countdown_aut - elapsed

            while state.countdown_aut <= 0 and
                #state.record_indices > 0 do
                collapse(ctx, state, player)
            end

            ctx:set(entity, component.WORLD_VOLCANO_COLLAPSE,
                state)
        end
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_VOLCANO_OVERFLOW,
    })) do
        local state = ctx:get(entity,
            component.WORLD_VOLCANO_OVERFLOW)

        if state.level_id == player.level_id and state.phase < 9 then
            state.countdown_aut = state.countdown_aut - elapsed

            while state.countdown_aut <= 0 and state.phase < 9 do
                overflow(ctx, state, player)
            end

            ctx:set(entity, component.WORLD_VOLCANO_OVERFLOW,
                state)
        end
    end
end

-- The scheduler and focused simulation tests share this operation. The
-- caller supplies the active player position; there is no second hazard
-- implementation in Go or in a test fixture.
function events.run(ctx, input)
    if not input.player or input.elapsed_aut <= 0 then
        error("Volcano hazard advance needs player and elapsed action time")
    end

    events.advance(ctx, input.player, input.elapsed_aut)

    return {}
end

register.policy({
    id = "world.volcano_hazards",
    run = events.run,
})

return events

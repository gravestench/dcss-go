-- Xom's stair repulsion uses one saved player timer and a directional
-- travel feature. The grid moves a linked stair or portal glyph and its
-- attached records; portal ECS clocks follow through stair_portals.
local chance = require("policy.religion.xom.selection_chance")
local channels = require("constants.message_channels")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local portals = require("policy.religion.xom.stair_portals")
local terrain = require("constants.terrain")
local trajectory = require("policy.combat.trajectory")
local vision = require("policy.character.vision")

local repel = {}

local adjacent = {
    { x = -1, y = -1 },
    { x = 0, y = -1 },
    { x = 1, y = -1 },
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
}

-- Linked stairs and directional portal or exit gates share source Xom
-- eligibility. The grid excludes shops and nontravel decoration.
function repel.nearby(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return {}
    end

    local nearby = {}
    local radius = vision.radius(ctx, player)

    for _, point in ipairs(ctx:visible_cells(origin.level_id,
        origin.x, origin.y, radius)) do
        if ctx:travel_feature_at(origin.level_id, point.x, point.y) then
            nearby[#nearby + 1] = point
        end
    end

    return nearby
end

-- When a stair begins under the player, the source first shoves it onto
-- nearby floor. Prefer a direction with another floor beyond that first
-- cell, then let the normal outward ray take it farther.
local function direction_from_under(ctx, origin, stream)
    local fallback = {}
    local preferred = {}

    for _, offset in ipairs(adjacent) do
        local x = origin.x + offset.x
        local y = origin.y + offset.y

        if ctx:cell(origin.level_id, x, y) == terrain.DNGN_FLOOR and
            not ctx:actor_at(origin.level_id, x, y) then
            local point = { x = x, y = y }

            fallback[#fallback + 1] = point

            if ctx:cell(origin.level_id,
                x + offset.x, y + offset.y) ==
                terrain.DNGN_FLOOR then
                preferred[#preferred + 1] = point
            end
        end
    end

    local choices = #preferred > 0 and preferred or fallback

    if #choices == 0 then
        return nil
    end

    return choices[ctx:random(stream, #choices) + 1]
end

-- Follow the source ray beyond the stair and use its farthest visible,
-- unoccupied floor cell. A wall, a closed door, or the sight edge ends it.
local function destination(ctx, origin, stair, stream)
    local aim = stair

    if stair.x == origin.x and stair.y == origin.y then
        aim = direction_from_under(ctx, origin, stream)
    end

    if not aim then
        return nil
    end

    local radius = vision.radius(ctx, ctx:player())
    local ray = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, aim.x, aim.y, radius, false)
    local last
    local reached_stair = stair.x == origin.x and
        stair.y == origin.y

    for _, point in ipairs(ray.path) do
        if point.x == stair.x and point.y == stair.y then
            reached_stair = true
        elseif reached_stair and
            ctx:cell(origin.level_id, point.x, point.y) ==
                terrain.DNGN_FLOOR and
            not ctx:actor_at(origin.level_id, point.x, point.y) and
            ctx:visible(origin.level_id,
                origin.x, origin.y, radius,
                point.x, point.y) then
            last = point
        end
    end

    return last
end

-- A failed slide leaves the timer active, as in the source. Only a real
-- destination issues the transactional grid command.
function repel.slide(ctx, player, stair, stream)
    stream = stream or streams.RELIGION
    local origin = ctx:get(player, component.POSITION)

    if not origin or
        not ctx:travel_feature_at(origin.level_id, stair.x, stair.y) then
        return false
    end

    local target = destination(ctx, origin, stair, stream)

    if not target then
        return false
    end

    ctx:move_stair(origin.level_id,
        stair.x, stair.y, target.x, target.y)
    portals.move(ctx, origin.level_id,
        stair.x, stair.y, target.x, target.y)

    return true
end

-- Every event refreshes movement repulsion. Only the climb event refreshes
-- climb repulsion; the source leaves an existing climb timer alone when a
-- later movement-only event fires.
function repel.start(ctx, player, unclimbable)
    local previous = ctx:get(player, component.XOM_STAIR_REPEL)
    local state = {
        move_aut = 1000,
        climb_aut = unclimbable and 500 or
            (previous and previous.climb_aut or 0),
    }

    if ctx:has(player, component.XOM_STAIR_REPEL) then
        ctx:set(player, component.XOM_STAIR_REPEL, state)
    else
        ctx:add(player, component.XOM_STAIR_REPEL, state)
    end

    return state
end

-- Completed player actions count down the durations after movement and
-- stair use have observed the current action's state.
function repel.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.XOM_STAIR_REPEL)

    if not state or elapsed_aut <= 0 then
        return
    end

    state.move_aut = math.max(0, state.move_aut - elapsed_aut)
    state.climb_aut = math.max(0, state.climb_aut - elapsed_aut)

    if state.move_aut == 0 and state.climb_aut == 0 then
        ctx:remove(player, component.XOM_STAIR_REPEL)
    else
        ctx:set(player, component.XOM_STAIR_REPEL, state)
    end
end

-- At a climb command, a successful source roll moves the stair and spends
-- the action instead of travelling. Failure lets ordinary travel proceed.
function repel.attempt_climb(ctx, player, position, stream)
    local state = ctx:get(player, component.XOM_STAIR_REPEL)

    if not state or state.climb_aut <= 0 or
        not ctx:travel_feature_at(position.level_id,
            position.x, position.y) then
        return false
    end

    stream = stream or streams.RELIGION
    local percent = state.move_aut > 0 and 29 or 50

    percent = percent + math.floor(
        math.max(0, state.climb_aut - 200) / 20)

    if not chance.in_y(ctx, stream, percent, 100) then
        return false
    end

    if not repel.slide(ctx, player, position, stream) then
        return false
    end

    ctx:emit(channels.RELIGION,
        "The staircase moves away as you try to climb it!")

    return true
end

-- After a player lands on a stair, the move duration can shove it away.
-- Climb repulsion lowers the initial chance; older effects become weaker.
function repel.on_move(ctx, player, position, stream)
    local state = ctx:get(player, component.XOM_STAIR_REPEL)

    if not state or state.move_aut <= 0 or
        not ctx:travel_feature_at(position.level_id,
            position.x, position.y) then
        return false
    end

    stream = stream or streams.RELIGION
    local percent = state.climb_aut > 0 and 29 or 50

    percent = percent + math.floor(
        math.max(0, state.move_aut - 700) / 10)

    if chance.in_y(ctx, stream, percent, 100) and
        repel.slide(ctx, player, position, stream) then
        ctx:emit(channels.RELIGION,
            "The staircase slides away from you!")
        return true
    end

    return false
end

return repel

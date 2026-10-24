-- Xom's Cleaving grants the player temporary axe-like melee reach around
-- a primary target. The duration belongs to one saved ECS component;
-- melee chooses actual nearby hostiles when each attack occurs.
local component = require("constants.component")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local cleaving = {}

-- Grid order makes the secondary contact sequence stable across entity
-- creation order and saves with the same visible arrangement.
local function before(left, right)
    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- Source increase_duration adds 10–(9+severity) turns. Repeated grants
-- extend the same status instead of creating competing attack rules.
function cleaving.start(ctx, player, severity, stream)
    stream = stream or streams.RELIGION

    local current = ctx:get(player, component.XOM_CLEAVING)
    local added = (10 + ctx:random(stream,
        math.max(1, severity))) * 10
    local state = {
        remaining_aut = (current and current.remaining_aut or 0) + added,
    }

    if current then
        ctx:set(player, component.XOM_CLEAVING, state)
    else
        ctx:add(player, component.XOM_CLEAVING, state)
    end

    return state
end

-- Combat sees the remaining time, not the mere presence of a stale record.
function cleaving.active(ctx, player)
    local state = ctx:get(player, component.XOM_CLEAVING)

    return state ~= nil and state.remaining_aut > 0
end

-- Snapshot the targets before primary contact can kill or move its victim.
-- The source strikes other adjacent hostile actors after the main attack.
-- Sorting by grid position makes this sequence independent of entity IDs.
function cleaving.targets(ctx, player, primary)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return {}
    end

    local found = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if entity ~= player and entity ~= primary and
            targets.enemy(ctx, player, entity) then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local adjacent = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y)) == 1

            if health.current > 0 and position.level_id == origin.level_id
                and adjacent then
                found[#found + 1] = {
                    entity = entity,
                    x = position.x,
                    y = position.y,
                }
            end
        end
    end

    table.sort(found, before)

    local result = {}

    for _, entry in ipairs(found) do
        result[#result + 1] = entry.entity
    end

    return result
end

-- Completed player actions spend aut after their attacks resolve. Removing
-- an expired record prevents a later turn from cleaving accidentally.
function cleaving.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.XOM_CLEAVING)

    if not state or elapsed_aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.XOM_CLEAVING)
    else
        ctx:set(player, component.XOM_CLEAVING, state)
    end
end

return cleaving

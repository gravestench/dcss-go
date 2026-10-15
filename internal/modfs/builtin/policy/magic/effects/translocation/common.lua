local component = require("constants.component")
local catalog = require("policy.catalog")

local common = {}

function common.distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

function common.monsters(ctx, level_id)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.AI, component.POSITION, component.HEALTH })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if position.level_id == level_id and health.current > 0 then
            local actor = ctx:get(entity, component.ACTOR)

            if actor then
                found[#found + 1] = {
                    entity = entity,
                    position = position,
                    actor = actor,
                    definition = catalog.get("monsters", actor.kind_id),
                }
            end
        end
    end

    return found
end

function common.flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

function common.hit(ctx, target, amount)
    if amount <= 0 then
        return
    end

    local health = ctx:get(target, component.HEALTH)
    local before = health.current
    health.current = math.max(0, health.current - amount)
    ctx:set(target, component.HEALTH, health)

    if before > 0 and health.current == 0 then
        ctx:signal("player_kill", target)
    end
end

return common

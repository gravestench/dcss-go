local component = require("constants.component")
local catalog = require("policy.catalog")
local monster_health = require("policy.combat.monster_health")

local common = {}

-- Example: Positions (1, 1) and (3, 2) are two cells apart on the square grid.
-- Square-grid effects count diagonal and orthogonal separation by the larger axis.
function common.distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

-- Collect living AI-controlled actors with positions before translocation chooses targets.
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

-- Read monster flags from the catalog for translocation eligibility checks.
function common.flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Translocation damage signals a player kill when monster health reaches zero.
function common.hit(ctx, target, amount)
    if amount <= 0 then
        return
    end

    local health, dealt = monster_health.damage(ctx, target, amount,
        ctx:player())

    if dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", target)
    end
end

return common

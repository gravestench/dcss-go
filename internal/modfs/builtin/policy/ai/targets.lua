-- Actor allegiance is game policy. Decisions and attacks share this rule.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")

local targets = {}

local function allied(ctx, entity)
    if entity == ctx:player() then
        return true
    end

    local summon = ctx:get(entity, component.SUMMON)

    if summon and not summon.hostile then
        return true
    end

    return allegiance.charmed(ctx, entity)
end

function targets.enemy(ctx, attacker, defender)
    if attacker == defender then
        return false
    end

    if allegiance.frenzied(ctx, attacker) then
        return true
    end

    return allied(ctx, attacker) ~= allied(ctx, defender)
end

function targets.nearest(ctx, attacker, origin, sight)
    local chosen = nil
    local closest = sight + 1

    for _, entity in ipairs(ctx:query({
        "core.actor", "core.position", "core.health",
    })) do
        if targets.enemy(ctx, attacker, entity) and
            (entity ~= ctx:player() or
                invisibility.visible_to(ctx, entity, attacker)) then
            local position = ctx:get(entity, "core.position")
            local health = ctx:get(entity, "core.health")
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance < closest and
                ctx:visible(origin.level_id, origin.x, origin.y, sight,
                    position.x, position.y) then
                chosen = entity
                closest = distance
            end
        end
    end

    return chosen, closest
end

function targets.allied(ctx, entity)
    return allied(ctx, entity)
end

return targets

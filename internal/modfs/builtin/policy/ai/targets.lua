-- Actor allegiance is game policy. Decisions and attacks share this rule.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")
local attitudes = require("constants.vault_attitude")

local targets = {}

-- A monster's underlying side comes from its summon or authored attitude.
-- Beneficial magic compares this with the caster's current side so a charm
-- cannot make an otherwise hostile monster a trusted recipient.
function targets.real_allied(ctx, entity)
    if entity == ctx:player() then
        return true
    end

    local summon = ctx:get(entity, component.SUMMON)

    if summon and not summon.hostile then
        return true
    end

    local authored = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

    if authored and (authored.attitude == attitudes.FRIENDLY or
        authored.attitude == attitudes.GOOD_NEUTRAL or
        authored.attitude == attitudes.FELLOW_SLIME) then
        return true
    end

    return false
end

-- Combat uses temporary charm as well as the actor's underlying side.
local function allied(ctx, entity)
    return targets.real_allied(ctx, entity) or
        allegiance.charmed(ctx, entity)
end

-- Neutral actors are excluded before proximity can imply hostility.
local function neutral(ctx, entity)
    local authored = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

    return authored and authored.attitude == attitudes.NEUTRAL
end

-- Frenzy overrides normal allegiance; neutral actors and same-side actors otherwise remain untargetable.
-- Example: targets.enemy(ctx, monster, player) checks allegiance before choosing an attack.
function targets.enemy(ctx, attacker, defender)
    if attacker == defender then
        return false
    end

    if allegiance.frenzied(ctx, attacker) then
        return true
    end

    if neutral(ctx, attacker) or neutral(ctx, defender) then
        return false
    end

    return allied(ctx, attacker) ~= allied(ctx, defender)
end

-- Choose a visible enemy using the same allegiance rule as attacks.
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

-- Expose allegiance without duplicating summon and charm checks.
function targets.allied(ctx, entity)
    return allied(ctx, entity)
end

return targets

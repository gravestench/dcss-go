-- Actor allegiance is game policy. Decisions and attacks share this rule.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")
local attitudes = require("constants.attitude")

local targets = {}

-- The player's side is always friendly. Other actors keep the source side
-- recorded by their summon or vault owner; ordinary monsters are hostile.
function targets.real_attitude(ctx, entity)
    if entity == ctx:player() then
        return attitudes.FRIENDLY
    end

    local summon = ctx:get(entity, component.SUMMON)

    if summon then
        return summon.attitude
    end

    local authored = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

    if authored then
        return authored.attitude
    end

    return attitudes.HOSTILE
end

-- A charm affects combat decisions but does not rewrite saved real attitude.
function targets.attitude(ctx, entity)
    if allegiance.charmed(ctx, entity) then
        return attitudes.FRIENDLY
    end

    return targets.real_attitude(ctx, entity)
end

-- The player and both source-friendly variants are coaligned in combat.
local function allied_attitude(value)
    return value == attitudes.FRIENDLY or
        value == attitudes.GOOD_NEUTRAL or
        value == attitudes.FELLOW_SLIME
end

-- Beneficial magic compares the caster's temporary side with the target's
-- real side, so a newly charmed foe is not a trusted recipient.
function targets.real_allied(ctx, entity)
    return allied_attitude(targets.real_attitude(ctx, entity))
end

-- The ordinary enemy decision considers temporary charm and excludes a
-- neutral participant unless frenzy overrides normal allegiance.
local function allied(ctx, entity)
    return allied_attitude(targets.attitude(ctx, entity))
end

local function neutral(ctx, entity)
    return targets.attitude(ctx, entity) == attitudes.NEUTRAL
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
    local haunting = ctx:get(attacker, component.SUMMON_HAUNTING)

    if haunting and ctx:has(haunting.target, component.ACTOR) and
        targets.enemy(ctx, attacker, haunting.target) then
        local position = ctx:get(haunting.target, component.POSITION)
        local health = ctx:get(haunting.target, component.HEALTH)

        if position and health and health.current > 0 and
            position.level_id == origin.level_id then
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            -- Haunting fixes the route target even after it leaves sight.
            -- The later attack and spell owners still check visibility.
            return haunting.target, distance
        end
    end

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

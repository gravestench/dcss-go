local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local player_health = require("policy.combat.player_health")
local mirror = require("policy.combat.monster_support.injury_mirror")
local display = require("policy.combat.monster_support.display")
local causes = require("constants.damage_causes")
local senses = require("policy.character.senses")

local monster_health = {}

-- Damage to a spectral weapon can propagate to its owner unless the owner caused the hit.
local function share_spectral_damage(ctx, target, source, dealt)
    if dealt < 2 or not source or
        not ctx:has(target, component.SPECTRAL_WEAPON) then
        return
    end

    local summon = ctx:get(target, component.SUMMON)
    local owner = summon and summon.owner

    if not owner or source == owner or
        not ctx:has(owner, component.PLAYER) then
        return
    end

    local health = ctx:get(owner, component.HEALTH)
    local shared = math.min(math.floor(dealt / 2), health.current - 1)

    if shared > 0 then
        ctx:emit("combat", "Your spectral weapon shares its damage with you!")
        player_health.damage(ctx, owner, shared, false)
    end
end

-- Example: monster_health.damage(ctx, target, amount, source) with already dead target -> no further HP loss
-- Shared monster HP loss lets mutation effects observe damage actually
-- dealt after petrification, with an explicit source actor.
function monster_health.damage(ctx, target, amount, source, cause)
    local health = ctx:get(target, component.HEALTH)

    if not health then
        error("monster damage target has no health")
    end

    local before = health.current

    if before <= 0 then
        return health, 0
    end

    statuses.wake_hibernating(ctx, target)
    amount = statuses.petrified_damage(ctx, target, amount)

    local dealt = math.min(before, math.max(0, amount))

    health.current = before - dealt
    ctx:set(target, component.HEALTH, health)

    share_spectral_damage(ctx, target, source, dealt)

    if dealt > 0 and health.current > 0 and source and
        ctx:has(source, component.PLAYER) then
        local hit = {
            target = target,
            damage = dealt,
        }

        effects.trigger(ctx, source, capabilities.AFTER_MONSTER_DAMAGE, hit)
    end

    local returned = mirror.returned(ctx, target, dealt, source,
        cause or causes.ORDINARY)

    if returned > 0 then
        if senses.player_sees_actor(ctx, target) then
            ctx:emit("combat", "The " .. display.name(ctx, target) ..
                " mirrors the damage!")
        end

        if ctx:has(source, component.PLAYER) then
            player_health.damage(ctx, source, returned, false, target)
        else
            monster_health.damage(ctx, source, returned, target,
                causes.REFLECTED)
        end
    end

    return health, dealt
end

return monster_health

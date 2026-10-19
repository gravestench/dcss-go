-- A monster's Cause Fear radiates through LOS_NO_TRANS, frightening both
-- the player and susceptible opposing monsters. Source: mon-cast.cc.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")
local area = require("policy.combat.monster_mind_area")
local fear = require("policy.character.player_fear")
local hex = require("policy.combat.monster_spells.hex")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local display = require("policy.combat.monster_support.display")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local will = require("policy.magic.effects.zaps.will")

local effect = {}
local POWER_PER_HD = 18
local MAX_ENCHANT_POWER = 200
local profile = {
    power_hd_factor = POWER_PER_HD,
    cap = MAX_ENCHANT_POWER,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- Source monster fear reaches natural creatures with a mind and movement;
-- an already frightened victim cannot gain a duplicate fear enchantment.
local function eligible(ctx, caster, target)
    if ctx:has(target, component.PLAYER) then
        return fear.possible(ctx, target) and
            not fear.afraid_of(ctx, target, caster)
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local natural = false
    local stationary = false
    local harmless = false

    for _, kind in ipairs(definition.holiness or {}) do
        natural = natural or kind == holiness.NATURAL
    end

    for _, flag in ipairs(definition.flags or {}) do
        stationary = stationary or flag == flags.STATIONARY
        harmless = harmless or flag == flags.NO_THREAT
    end

    return natural and not (stationary and harmless) and
        not will.invulnerable(definition) and
        not mass.fear_active(ctx, target)
end

-- The AI checks eligibility without rolling will or changing ECS state.
function effect.plan(ctx, caster)
    if area.any(ctx, caster, eligible) then
        return self_target.plan(caster)
    end

    return nil
end

-- Source power is eighteen spell HD, capped at 200. Every victim makes
-- its own will check, and the affected actor owns the resulting timer.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                " radiates an aura of fear!")
    elseif senses.player_sees_cell(ctx,
        ctx:get(caster, component.POSITION)) then
        ctx:emit(channels.SPELL,
            "An aura of fear fills the air!")
    end

    local power = hex.enchantment_power(ctx, caster, profile)

    -- Recheck current positions because the saved self plan carries no
    -- stale victim list across the action boundary.
    local function frighten(current, source, victim)
        if current:has(victim, component.PLAYER) then
            if not fear.eligible(current, victim) then
                current:emit(channels.SPELL, "You are unaffected.")

                return
            end

            if hex.resisted(current, source, victim, profile) then
                current:emit(channels.SPELL, "You resist the fear.")

                return
            end

            fear.apply(current, victim, source, power)

            return
        end

        local actor = current:get(victim, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        mass.apply_monster_fear(current, victim, definition, power)
    end

    area.each(ctx, caster, eligible, frighten)
end

return effect

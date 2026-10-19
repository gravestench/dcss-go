-- Mass Confusion reaches each unaligned creature in LOS_NO_TRANS and
-- stores confusion on the victim that failed its own will contest.
-- Source: mon-cast.cc:_mons_mass_confuse.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local area = require("policy.combat.monster_mind_area")
local hex = require("policy.combat.monster_spells.hex")
local player_confusion = require("policy.magic.player_confusion")
local player_resistance = require("policy.combat.player_resistance")
local monster_confusion = require(
    "policy.magic.effects.statuses.confusing_touch")
local self_target = require("policy.combat.monster_support.self_target")
local streams = require("constants.rng_streams")
local will = require("policy.magic.effects.zaps.will")

local effect = {}
local POWER_PER_HD = 8
local MAX_ENCHANT_POWER = 200
local MIN_CONFUSION_TURNS = 5
local EXTRA_CONFUSION_TURNS = 3
local profile = {
    power_hd_factor = POWER_PER_HD,
    cap = MAX_ENCHANT_POWER,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- The source excludes invulnerable-willed and firewood monsters before
-- rolling. Player clarity is checked after will, inside resolution.
local function eligible(ctx, _, target)
    if ctx:has(target, component.PLAYER) then
        return true
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local stationary = false
    local harmless = false

    for _, flag in ipairs(definition.flags or {}) do
        stationary = stationary or flag == flags.STATIONARY
        harmless = harmless or flag == flags.NO_THREAT
    end

    return not will.invulnerable(definition) and
        not (stationary and harmless)
end

-- One possible victim makes the self-centered area worth offering to AI;
-- no will checks or duration draws belong in planning.
function effect.plan(ctx, caster)
    if area.any(ctx, caster, eligible) then
        return self_target.plan(caster)
    end

    return nil
end

-- Recheck the area, roll each will contest, and add five to seven turns
-- of saved confusion only to actors that fail.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    -- Source `monster::confuse` and `you.confuse` may still reject a body
    -- with clarity after the spell has passed its will contest.
    local function confuse(current, source, victim)
        if hex.resisted(current, source, victim, profile) then
            if current:has(victim, component.PLAYER) then
                current:emit(channels.SPELL,
                    "You resist the confusion.")
            end

            return
        end

        if current:has(victim, component.PLAYER) then
            if player_resistance.clarity(current, victim) then
                current:emit(channels.SPELL,
                    "You feel momentarily confused.")

                return
            end

            local turns = MIN_CONFUSION_TURNS + current:random(
                streams.MONSTER_SPELL, EXTRA_CONFUSION_TURNS)

            player_confusion.extend(current, victim, turns)
            current:emit(channels.SPELL, "You feel confused.")

            return
        end

        local actor = current:get(victim, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        for _, flag in ipairs(definition.flags or {}) do
            if flag == flags.CLARITY then
                return
            end
        end

        local turns = MIN_CONFUSION_TURNS + current:random(
            streams.MONSTER_SPELL, EXTRA_CONFUSION_TURNS)

        monster_confusion.apply_turns(current, victim,
            definition, turns)
    end

    area.each(ctx, caster, eligible, confuse)
end

return effect

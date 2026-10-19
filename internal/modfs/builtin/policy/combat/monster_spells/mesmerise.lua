-- Mesmerise fixes one player foe as the target and adds that monster to
-- the player's saved beholder list after a failed will contest.
-- Source: mon-cast.cc:_mons_mesmerise.
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local hex = require("policy.combat.monster_spells.hex")
local mesmerism = require("policy.character.player_mesmerism")
local invisibility = require("policy.potions.invisibility")
local resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local effect = {}
local POWER_PER_HD = 10
local MAX_ENCHANT_POWER = 200
local profile = {
    power_hd_factor = POWER_PER_HD,
    cap = MAX_ENCHANT_POWER,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- Only the selected player can be mesmerised. The source also needs mutual
-- awareness and hearing before the AI offers this cast.
function effect.plan(ctx, caster, foe)
    if not foe or not ctx:has(foe, component.PLAYER) or
        not invisibility.visible_to(ctx, foe, caster) or
        not mesmerism.can_start(ctx, foe, caster, true) then
        return nil
    end

    if mesmerism.beheld_by(ctx, foe, caster) and
        ctx:random(streams.MONSTER_SPELL, 2) == 0 then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Source still checks will on a familiar victim, then ignores that result:
-- an existing hold can be refreshed until the player breaks free.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    if not invisibility.visible_to(ctx, foe, caster) or
        not mesmerism.can_start(ctx, foe, caster, true) then
        return
    end

    local familiar = mesmerism.beheld_by(ctx, foe, caster)

    if senses.player_sees_actor(ctx, caster) then
        local message = familiar and " draws you further into its thrall." or
            " attempts to bespell you!"

        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) .. message)
    end

    local resisted = hex.resisted(ctx, caster, foe, profile)
    local state = ctx:get(foe, component.PLAYER_MESMERISM)
    local immune = state and state.immune_aut > 0

    if not familiar and
        (resisted or immune or resistance.clarity(ctx, foe)) then
        ctx:emit(channels.SPELL,
            immune and "You resist the enchantment." or
                "You are unaffected.")
        return
    end

    mesmerism.apply(ctx, foe, caster)
end

return effect

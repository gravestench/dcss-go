-- Chaos enchantments share the beam's actor contact, but their status is
-- applied by the existing hex and status owners. The player may resist a
-- hostile enchantment; source monster targets skip willpower when the real
-- beam flavour is Chaos. Source: beam.cc:try_enchant_monster and
-- bolt::affect_player_enchantment.
-- Example: hexes.apply(ctx, caster, foe, BEAM_CONFUSION, 17) gives a
-- monster an unresisted confusion attempt at this arc's current power.
local banishment = require("policy.combat.monster_hexes.banishment")
local component = require("constants.component")
local confuse = require("policy.combat.monster_hexes.confuse")
local flavours = require("constants.beam_flavours")
local hex = require("policy.combat.monster_spells.hex")
local monster_stasis = require(
    "policy.magic.effects.statuses.monster_stasis")
local paralyse = require("policy.combat.monster_hexes.paralyse")
local player_petrification = require(
    "policy.combat.player_petrification")
local polymorph = require("policy.combat.monster_hexes.polymorph")
local slow = require("policy.combat.monster_hexes.slow")
local streams = require("constants.rng_streams")

local hexes = {}

local profile = {
    cap = 200,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- Petrification already has separate player and monster phase owners.
-- Keep its status representation with them rather than in Chaos policy.
local function petrify(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return player_petrification.apply(ctx, defender)
    end

    return monster_stasis.apply_petrify(ctx, defender)
end

local rules = {
    [flavours.BEAM_CONFUSION] = confuse,
    [flavours.BEAM_BANISH] = banishment,
    [flavours.BEAM_SLOW] = slow,
    [flavours.BEAM_PARALYSIS] = paralyse,
    [flavours.BEAM_PETRIFY] = {
        apply = petrify,
    },
    [flavours.BEAM_POLYMORPH] = polymorph,
}

-- Apply a selected status using the current jump's attenuated power.
-- Monster willpower is bypassed only for the real Chaos beam; player
-- willpower, viability, and each status owner's immunity still apply.
function hexes.apply(ctx, caster, defender, flavour, power)
    local rule = rules[flavour]

    if not rule then
        error("unknown chain chaos hex " .. tostring(flavour))
    end

    if rule.viable and
        not rule.viable(ctx, caster, defender, profile) then
        return false
    end

    if ctx:has(defender, component.PLAYER) and
        hex.resisted(ctx, caster, defender, profile, power) then
        return false
    end

    rule.apply(ctx, caster, defender, profile, power)

    return true
end

-- The impact dispatcher checks this table before routing to damage or
-- boon handlers, avoiding a long conditional over all Chaos flavours.
function hexes.handles(flavour)
    return rules[flavour] ~= nil
end

return hexes

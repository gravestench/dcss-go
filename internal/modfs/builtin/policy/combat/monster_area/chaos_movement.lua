-- Chain of Chaos can move an actor instead of damaging it. Blink resolves
-- immediately; Teleport schedules travel and can cancel an existing timer.
-- Source: beam.cc:apply_enchantment_to_monster and affect_player_enchantment.
-- Example: movement.apply(ctx, caster, player, BEAM_BLINK, 17) uses the
-- ordinary player landing rules without a willpower save.
local component = require("constants.component")
local flavours = require("constants.beam_flavours")
local hex = require("policy.combat.monster_spells.hex")
local landing = require("policy.combat.monster_displacement.landing")
local monster_teleport = require(
    "policy.magic.effects.zaps.teleport_other")
local player_teleport = require("policy.magic.player_teleport")
local relocate = require("policy.combat.monster_displacement.relocate")
local streams = require("constants.rng_streams")

local movement = {}

local teleport_profile = {
    cap = 200,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- Reuse each actor's landing and movement owner. Source Blink has no
-- saving throw, and a failed landing simply leaves the actor in place.
local function blink(ctx, caster, defender)
    if not relocate.can_move(ctx, defender) then
        return false
    end

    local x, y = landing.ordinary(ctx, defender)

    if not x then
        return false
    end

    return relocate.move(ctx, defender, x, y, caster)
end

-- Only the player can save against Chaos Teleport. The source Chaos beam
-- bypasses monster willpower, while no-tele status still blocks travel.
local function teleport(ctx, caster, defender, power)
    if ctx:has(defender, component.PLAYER) then
        if hex.resisted(ctx, caster, defender,
            teleport_profile, power) then
            return false
        end

        player_teleport.toggle(ctx, defender, streams.MONSTER_SPELL)

        return true
    end

    return monster_teleport.schedule(ctx, defender,
        streams.MONSTER_SPELL)
end

-- Route movement flavours without copying the two actors' placement rules.
function movement.apply(ctx, caster, defender, flavour, power)
    if flavour == flavours.BEAM_BLINK then
        return blink(ctx, caster, defender)
    end

    if flavour == flavours.BEAM_TELEPORT then
        return teleport(ctx, caster, defender, power)
    end

    error("unknown chain chaos movement " .. tostring(flavour))
end

-- The impact dispatcher uses this predicate before resolving beam contact.
function movement.handles(flavour)
    return flavour == flavours.BEAM_BLINK or
        flavour == flavours.BEAM_TELEPORT
end

return movement

-- Chaos Mindburst is a mental enchantment with direct health damage.
-- Armour and elemental resistance never reduce it. Source: beam.cc:
-- BEAM_MINDBURST in apply_enchantment_to_monster and player handling.
-- Example: mindburst.apply(ctx, caster, foe, 17, profile) rolls the arc's
-- damage dice only after target viability and any player will save.
local calculators = require("policy.combat.monster_beams.calculators")
local component = require("constants.component")
local damage = require("policy.combat.monster_hexes.damage")
local hex = require("policy.combat.monster_spells.hex")
local viability = require("policy.combat.monster_hexes.mindburst")

local mindburst = {}

-- Brainless monsters cannot receive mental damage. The original Chaos
-- flavour bypasses monster willpower, but not this biological immunity.
local function viable(ctx, caster, defender)
    return viability.viable(ctx, caster, defender)
end

-- A player can resist the current arc's enchantment power before dice roll.
local function resisted(ctx, caster, defender, power, profile)
    return ctx:has(defender, component.PLAYER) and
        hex.resisted(ctx, caster, defender, profile, power)
end

-- Source damage is calculated from attenuated arc power and skips armour.
function mindburst.apply(ctx, caster, defender, _, power, profile)
    if not viable(ctx, caster, defender) or
        resisted(ctx, caster, defender, power, profile) then
        return false
    end

    local dice = calculators.damage_dice(ctx, profile, power)
    local amount = calculators.roll_damage(ctx, dice,
        profile.rng_stream)

    damage.apply(ctx, caster, defender, amount)

    return true
end

return mindburst

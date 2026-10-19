local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local vampire = require("policy.character.vampire")

local vampirism = {}

-- Vampirism's resistance and stealth outputs depend on the current blood state.
-- Example: bloodless state contributes -20 HP percent; alive state contributes zero here.
function vampirism.hp_percent(_, ctx, player)
    return vampire.bloodless(ctx, player) and -20 or 0
end

-- Only a fully alive vampire gains the blood-fed regeneration bonus; the
-- vampire state reader applies the same threshold used by other blood rules.
function vampirism.regeneration(_, ctx, player)
    return vampire.alive(ctx, player) and 20 or 0
end

-- Bloodless vampires trade regeneration for undead defenses. Returning a
-- binary flag lets the shared regeneration rule stop healing altogether.
function vampirism.regeneration_inhibited(_, ctx, player)
    return vampire.bloodless(ctx, player) and 1 or 0
end

-- Bloodlessness grants cold resistance as part of the undead-like state;
-- the common resistance collector adds these two pips to other sources.
function vampirism.cold_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 2 or 0
end

-- The bloodless state grants full negative-energy resistance; return zero
-- while alive so the ordinary living-vampire rules remain in effect.
function vampirism.negative_energy_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 3 or 0
end

-- Bloodlessness also removes ordinary poison vulnerability. The collector
-- receives three pips here, matching the legacy immunity threshold.
function vampirism.poison_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 3 or 0
end

-- Torment resistance follows the same bloodless gate as the other undead
-- defenses, while alive vampires receive no bonus from this mutation.
function vampirism.torment_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 2 or 0
end

-- Bloodless vampires are harder to detect; this returns the flat stealth
-- contribution for the shared stealth calculation rather than changing it.
function vampirism.stealth(_, ctx, player)
    return vampire.bloodless(ctx, player) and 100 or 0
end

registry.add(mutations.MUT_VAMPIRISM, {
    [capabilities.HP_PERCENT] = vampirism.hp_percent,
    [capabilities.HP_REGEN_BONUS] = vampirism.regeneration,
    [capabilities.HP_REGEN_INHIBITED] =
        vampirism.regeneration_inhibited,
    [capabilities.COLD_RESISTANCE] = vampirism.cold_resistance,
    [capabilities.NEGATIVE_ENERGY_RESISTANCE] =
        vampirism.negative_energy_resistance,
    [capabilities.POISON_RESISTANCE] = vampirism.poison_resistance,
    [capabilities.TORMENT_RESISTANCE] =
        vampirism.torment_resistance,
    [capabilities.STEALTH_BONUS] = vampirism.stealth,
    [capabilities.ON_CHANGE] = vampire.changed,
})

return vampirism

local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local vampire = require("policy.character.vampire")

local vampirism = {}

function vampirism.hp_percent(_, ctx, player)
    return vampire.bloodless(ctx, player) and -20 or 0
end

function vampirism.regeneration(_, ctx, player)
    return vampire.alive(ctx, player) and 20 or 0
end

function vampirism.regeneration_inhibited(_, ctx, player)
    return vampire.bloodless(ctx, player) and 1 or 0
end

function vampirism.cold_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 2 or 0
end

function vampirism.negative_energy_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 3 or 0
end

function vampirism.poison_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 3 or 0
end

function vampirism.torment_resistance(_, ctx, player)
    return vampire.bloodless(ctx, player) and 2 or 0
end

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

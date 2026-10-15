local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local resistances = {}

-- Source: player.cc:player::res_fire, res_cold, and res_elec.
function resistances.level(level)
    return level
end

function resistances.vulnerability(level)
    return -level
end

function resistances.metallic_scales(level)
    return level == 3 and 1 or 0
end

-- Source: player.cc:player_res_poison.
function resistances.slimy_scales(level)
    return level == 3 and 1 or 0
end

function resistances.yellow_scales(level)
    return level == 3 and 1 or 0
end

function resistances.steam(level)
    return level * 2
end

registry.add(mutations.MUT_HEAT_RESISTANCE, {
    [capabilities.FIRE_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_HEAT_VULNERABILITY, {
    [capabilities.FIRE_RESISTANCE] = resistances.vulnerability,
})

registry.add(mutations.MUT_COLD_RESISTANCE, {
    [capabilities.COLD_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_COLD_VULNERABILITY, {
    [capabilities.COLD_RESISTANCE] = resistances.vulnerability,
})

registry.add(mutations.MUT_TEMPERATURE_SENSITIVITY, {
    [capabilities.FIRE_RESISTANCE] = resistances.vulnerability,
    [capabilities.COLD_RESISTANCE] = resistances.vulnerability,
})

registry.add(mutations.MUT_SHOCK_RESISTANCE, {
    [capabilities.ELECTRICITY_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_SHOCK_VULNERABILITY, {
    [capabilities.ELECTRICITY_RESISTANCE] = resistances.vulnerability,
})

registry.add(mutations.MUT_THIN_METALLIC_SCALES, {
    [capabilities.ELECTRICITY_RESISTANCE] = resistances.metallic_scales,
})

registry.add(mutations.MUT_POISON_RESISTANCE, {
    [capabilities.POISON_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_SLIMY_GREEN_SCALES, {
    [capabilities.POISON_RESISTANCE] = resistances.slimy_scales,
})

registry.add(mutations.MUT_CLARITY, {
    [capabilities.CLARITY] = resistances.level,
})

registry.add(mutations.MUT_ACID_RESISTANCE, {
    [capabilities.ACID_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_YELLOW_SCALES, {
    [capabilities.ACID_RESISTANCE] = resistances.yellow_scales,
})

registry.add(mutations.MUT_STEAM_RESISTANCE, {
    [capabilities.STEAM_RESISTANCE] = resistances.steam,
})

registry.add(mutations.MUT_NEGATIVE_ENERGY_RESISTANCE, {
    [capabilities.NEGATIVE_ENERGY_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_TORMENT_RESISTANCE, {
    [capabilities.TORMENT_RESISTANCE] = resistances.level,
})

registry.add(mutations.MUT_PETRIFICATION_RESISTANCE, {
    [capabilities.PETRIFICATION_RESISTANCE] = resistances.level,
})

return resistances

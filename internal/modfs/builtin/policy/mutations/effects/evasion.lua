local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local evasion = {}

function evasion.gelatinous(level)
    return level
end

function evasion.distortion(level)
    return level > 0 and level + 1 or 0
end

function evasion.slow_reflexes(level)
    return -level * 5
end

registry.add(mutations.MUT_GELATINOUS_BODY, {
    [capabilities.EVASION_BONUS] = evasion.gelatinous,
})

registry.add(mutations.MUT_DISTORTION_FIELD, {
    [capabilities.EVASION_BONUS] = evasion.distortion,
})

registry.add(mutations.MUT_SLOW_REFLEXES, {
    [capabilities.EVASION_BONUS] = evasion.slow_reflexes,
})

return evasion

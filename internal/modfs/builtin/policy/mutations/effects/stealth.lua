local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local stealth = {}

function stealth.pips(level)
    return 50 * level
end

function stealth.backlit(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_CAMOUFLAGE, {
    [capabilities.STEALTH_BONUS] = stealth.pips,
})

registry.add(mutations.MUT_THIN_SKELETAL_STRUCTURE, {
    [capabilities.STEALTH_BONUS] = stealth.pips,
})

registry.add(mutations.MUT_GLOWING, {
    [capabilities.BACKLIT] = stealth.backlit,
})

return stealth

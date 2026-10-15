local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local willpower = {}

function willpower.strong(level)
    return level
end

function willpower.weak(level)
    return -level
end

registry.add(mutations.MUT_STRONG_WILLED, {
    [capabilities.WILLPOWER_PIPS] = willpower.strong,
})

registry.add(mutations.MUT_DEMONIC_WILL, {
    [capabilities.WILLPOWER_PIPS] = willpower.strong,
})

registry.add(mutations.MUT_WEAK_WILLED, {
    [capabilities.WILLPOWER_PIPS] = willpower.weak,
})

return willpower

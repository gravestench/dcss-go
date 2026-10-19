local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local willpower = {}

-- Strong and weak will mutation levels are kept separate for the final will formula.
-- Example: Strong Will level two contributes +2; Weak Will level two contributes -2.
function willpower.strong(level)
    return level
end

-- Weak-Willed contributes negative pips through the shared willpower sum,
-- which keeps opposed mutations from needing a special case in defense.
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

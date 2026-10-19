local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local accuracy = {}

-- The missing-eye penalty is exposed as a formula for the combat accuracy calculation.
-- Example: one Missing Eye level returns one accuracy-penalty flag; further levels do not stack it.
function accuracy.missing_eye(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_MISSING_EYE, {
    [capabilities.INACCURACY] = accuracy.missing_eye,
})

return accuracy

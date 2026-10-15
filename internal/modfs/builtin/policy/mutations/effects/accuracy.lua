local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local accuracy = {}

function accuracy.missing_eye(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_MISSING_EYE, {
    [capabilities.INACCURACY] = accuracy.missing_eye,
})

return accuracy

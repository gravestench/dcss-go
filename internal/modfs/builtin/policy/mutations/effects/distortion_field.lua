local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local distortion_field = {}

function distortion_field.missile_repulsion(level)
    return level >= 3 and 1 or 0
end

registry.add(mutations.MUT_DISTORTION_FIELD, {
    [capabilities.MISSILE_REPULSION] = distortion_field.missile_repulsion,
})

return distortion_field

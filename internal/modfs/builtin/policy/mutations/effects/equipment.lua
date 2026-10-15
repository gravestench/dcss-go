local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local equipment = {}

function equipment.forbidden(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_NO_ARMOUR, {
    [capabilities.ARMOUR_USE_FORBIDDEN] = equipment.forbidden,
})

registry.add(mutations.MUT_NO_GRASPING, {
    [capabilities.HANDHELD_USE_FORBIDDEN] = equipment.forbidden,
})

return equipment

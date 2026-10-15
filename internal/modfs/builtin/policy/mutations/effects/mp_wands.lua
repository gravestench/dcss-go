local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local mp_wands = {}

function mp_wands.cost(level)
    return 3 * level
end

registry.add(mutations.MUT_MP_WANDS, {
    [capabilities.WAND_MP_COST] = mp_wands.cost,
})

return mp_wands

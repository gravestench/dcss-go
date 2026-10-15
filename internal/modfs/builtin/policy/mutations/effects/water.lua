local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local water = {}

function water.swimmer_level(level)
    return level
end

effects.add(mutations.MUT_NIMBLE_SWIMMER, {
    [capabilities.SWIMMER_LEVEL] = water.swimmer_level,
})

return water

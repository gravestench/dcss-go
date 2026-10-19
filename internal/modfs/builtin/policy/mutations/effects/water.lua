local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local water = {}

-- The swimmer level is shared with movement rules for shallow and deep water.
-- Example: swimmer capability mirrors mutation level so water rules can test effective rank.
function water.swimmer_level(level)
    return level
end

effects.add(mutations.MUT_NIMBLE_SWIMMER, {
    [capabilities.SWIMMER_LEVEL] = water.swimmer_level,
})

return water

local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local resources = {}

-- Magic-resource eligibility is read from the live mutation state.
-- Example: level one enables the magic-resource capability; higher levels keep the same boolean result.
function resources.enabled(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_MANA_SHIELD, {
    [capabilities.SPIRIT_SHIELD] = resources.enabled,
})

registry.add(mutations.MUT_MANA_LINK, {
    [capabilities.MANA_LINK] = resources.enabled,
})

return resources

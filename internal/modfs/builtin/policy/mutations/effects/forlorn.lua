local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local forlorn = {}

-- Source: god-prayer.cc:try_god_conversion and religion.cc:
-- player_can_join_god. The character may have no religion at any time.
-- Example: Forlorn level one forbids worship while leaving the existing god record intact.
function forlorn.worship_forbidden(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_FORLORN, {
    [capabilities.WORSHIP_FORBIDDEN] = forlorn.worship_forbidden,
})

return forlorn

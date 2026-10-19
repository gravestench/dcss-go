local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local short_lifespan = {}

-- Short lifespan changes the XP divisor used by experience progression.
-- Example: Short Lifespan contributes nine to the Zot clock divisor only while present.
function short_lifespan.extra_divisor(level)
    if level > 0 then
        return 9
    end

    return 0
end

effects.add(mutations.MUT_SHORT_LIFESPAN, {
    [capabilities.ZOT_CLOCK_EXTRA_DIVISOR] = short_lifespan.extra_divisor,
})

return short_lifespan

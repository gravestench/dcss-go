local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local short_lifespan = {}

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

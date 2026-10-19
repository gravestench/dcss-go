local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local flight = {}

-- Permanent flight and Tengu flight are separate capability checks for movement policy.
-- Example: permanent flight returns one presence flag at any positive mutation level.
function flight.permanent(level)
    return level > 0 and 1 or 0
end

-- Mark Tengu flight as its own perk as well as generic permanent flight;
-- species-specific rules can test this without inspecting mutation IDs.
function flight.tengu(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_TENGU_FLIGHT, {
    [capabilities.PERMANENT_FLIGHT] = flight.permanent,
    [capabilities.TENGU_FLIGHT_PERK] = flight.tengu,
})

registry.add(mutations.MUT_BIG_WINGS, {
    [capabilities.PERMANENT_FLIGHT] = flight.permanent,
})

registry.add(mutations.MUT_FLOAT, {
    [capabilities.PERMANENT_FLIGHT] = flight.permanent,
})

return flight

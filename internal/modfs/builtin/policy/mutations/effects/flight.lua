local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local flight = {}

function flight.permanent(level)
    return level > 0 and 1 or 0
end

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

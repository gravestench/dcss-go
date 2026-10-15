local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local movement = {}

function movement.fast_reduction(level)
    return level > 0 and level + 1 or 0
end

function movement.slow_level(level)
    return level
end

registry.add(mutations.MUT_FAST, {
    [capabilities.MOVE_FAST_REDUCTION] = movement.fast_reduction,
})

registry.add(mutations.MUT_SLOW, {
    [capabilities.MOVE_SLOW_LEVEL] = movement.slow_level,
})

return movement

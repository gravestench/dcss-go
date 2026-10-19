local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local noise = {}

-- Noise dampening and involuntary shout level are distinct mutation outputs.
-- Example: Noise Dampening is a presence flag, while Shouting forwards its level as volume input.
function noise.dampening(level)
    return level > 0 and 1 or 0
end

-- Feed the full mutation level to shout scheduling; the event owner decides
-- when a noisy outburst happens rather than this scalar adapter.
function noise.shout_level(level)
    return level
end

registry.add(mutations.MUT_NOISE_DAMPENING, {
    [capabilities.NOISE_DAMPENING] = noise.dampening,
})

registry.add(mutations.MUT_SCREAM, {
    [capabilities.SHOUT_LEVEL] = noise.shout_level,
})

return noise

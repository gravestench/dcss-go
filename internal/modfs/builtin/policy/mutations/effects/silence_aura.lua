-- Source: areas.cc:player::demon_silence_radius.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local silence_aura = {}

function silence_aura.radius(level)
    return level > 0 and 1 or 0
end

effects.add(mutations.MUT_SILENCE_AURA, {
    [capabilities.SILENCE_RADIUS] = silence_aura.radius,
})

return silence_aura

-- Source: player.cc:player::innate_sinv.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local acute_vision = {}

function acute_vision.see_invisible(level)
    return level > 0 and 1 or 0
end

effects.add(mutations.MUT_ACUTE_VISION, {
    [capabilities.SEE_INVISIBLE] = acute_vision.see_invisible,
})

return acute_vision

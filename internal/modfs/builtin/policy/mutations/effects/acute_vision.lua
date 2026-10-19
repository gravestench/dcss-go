-- Source: player.cc:player::innate_sinv.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local acute_vision = {}

-- Convert acquired mutation levels to one visibility capability; extra ranks do not stack sight.
-- Example: one Acute Vision level grants see invisible, while a zero-level record contributes nothing.
function acute_vision.see_invisible(level)
    return level > 0 and 1 or 0
end

effects.add(mutations.MUT_ACUTE_VISION, {
    [capabilities.SEE_INVISIBLE] = acute_vision.see_invisible,
})

return acute_vision

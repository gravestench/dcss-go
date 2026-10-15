-- Source: player.cc:player_monster_detect_radius and player::innate_sinv.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local antennae = {}

function antennae.detect_radius(level)
    return level * 2
end

function antennae.see_invisible(level)
    return level >= 3 and 1 or 0
end

effects.add(mutations.MUT_ANTENNAE, {
    [capabilities.MONSTER_DETECTION_RADIUS] = antennae.detect_radius,
    [capabilities.SEE_INVISIBLE] = antennae.see_invisible,
})

return antennae

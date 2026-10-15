local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local vision = {}

function vision.daystalker(level)
    return level
end

function vision.nightstalker(level)
    return -level
end

function vision.nightstalker_stealth(level)
    -- player.cc:player_stealth grants 50 * level / 3, rounded down.
    return math.floor(50 * level / 3)
end

registry.add(mutations.MUT_DAYSTALKER, {
    [capabilities.VISION_RADIUS_BONUS] = vision.daystalker,
})

registry.add(mutations.MUT_NIGHTSTALKER, {
    [capabilities.VISION_RADIUS_BONUS] = vision.nightstalker,
    [capabilities.STEALTH_BONUS] = vision.nightstalker_stealth,
})

return vision

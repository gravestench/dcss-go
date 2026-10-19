local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local vision = {}

-- Daystalker adds one sight cell per rank; Nightstalker's subtraction is a separate capability.
-- Example: vision.daystalker(2) adds two sight cells; vision.nightstalker(2) removes two.
function vision.daystalker(level)
    return level
end

-- Nightstalker shortens sight by one per level; the vision owner combines
-- that negative radius with other sources of light and perception.
function vision.nightstalker(level)
    return -level
end

-- Floor the source's one-third stealth scale here so callers share the same
-- integer value instead of rounding it in different places.
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

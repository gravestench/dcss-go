local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local evasion = {}

-- Gelatinous, distortion, and slow-reflex modifiers feed the evasion formula separately.
-- Example: Distortion Field level two contributes three evasion; Slow Reflexes level two subtracts ten.
function evasion.gelatinous(level)
    return level
end

-- The first Distortion Field level already grants more than a single point;
-- inactive level zero still contributes nothing.
function evasion.distortion(level)
    return level > 0 and level + 1 or 0
end

-- Apply a per-level evasion penalty through the same additive capability as
-- positive mutations, letting defense sum both effects consistently.
function evasion.slow_reflexes(level)
    return -level * 5
end

registry.add(mutations.MUT_GELATINOUS_BODY, {
    [capabilities.EVASION_BONUS] = evasion.gelatinous,
})

registry.add(mutations.MUT_DISTORTION_FIELD, {
    [capabilities.EVASION_BONUS] = evasion.distortion,
})

registry.add(mutations.MUT_SLOW_REFLEXES, {
    [capabilities.EVASION_BONUS] = evasion.slow_reflexes,
})

return evasion

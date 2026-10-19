local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local stealth = {}

-- Stealth pips and backlighting are derived from different mutation conditions.
-- Example: stealth level two adds 100 pips; backlighting contributes a separate presence flag.
function stealth.pips(level)
    return 50 * level
end

-- Mark any active glow as a boolean backlight gate; stealth calculation owns
-- the resulting visibility penalty.
function stealth.backlit(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_CAMOUFLAGE, {
    [capabilities.STEALTH_BONUS] = stealth.pips,
})

registry.add(mutations.MUT_THIN_SKELETAL_STRUCTURE, {
    [capabilities.STEALTH_BONUS] = stealth.pips,
})

registry.add(mutations.MUT_GLOWING, {
    [capabilities.BACKLIT] = stealth.backlit,
})

return stealth

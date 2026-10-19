local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local immunity = {}

-- Publish an on/off capability so cloud contact can short-circuit without reading mutation records.
-- Example: Cloud Immunity level one contributes a flag; a zero-level record contributes none.
function immunity.active(level)
    return level > 0 and 1 or 0
end

-- Source: cloud.cc:actor_cloud_immune and player.cc:player::res_miasma.
registry.add(mutations.MUT_IGNITE_BLOOD, {
    [capabilities.FIRE_CLOUD_IMMUNITY] = immunity.active,
})

registry.add(mutations.MUT_FLAME_CLOUD_IMMUNITY, {
    [capabilities.FIRE_CLOUD_IMMUNITY] = immunity.active,
})

registry.add(mutations.MUT_FREEZING_CLOUD_IMMUNITY, {
    [capabilities.COLD_CLOUD_IMMUNITY] = immunity.active,
})

registry.add(mutations.MUT_FOUL_STENCH, {
    [capabilities.MIASMA_IMMUNITY] = immunity.active,
})

return immunity

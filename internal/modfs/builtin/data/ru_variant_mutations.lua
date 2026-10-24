-- Ru offers one mutation from each named source vector. Essence retains
-- Weak-Willed twice because that duplicate changes its draw probability.
local mutations = require("ids.mutations")
local pools = require("constants.ru_variant_pools")

local variants = {
    [pools.HEALTH] = {
        mutations.MUT_FRAIL,
        mutations.MUT_PHYSICAL_VULNERABILITY,
        mutations.MUT_SLOW_REFLEXES,
    },
    [pools.ESSENCE] = {
        mutations.MUT_ANTI_WIZARDRY,
        mutations.MUT_WEAK_WILLED,
        mutations.MUT_WEAK_WILLED,
        mutations.MUT_LOW_MAGIC,
    },
    [pools.PURITY] = {
        mutations.MUT_SCREAM,
        mutations.MUT_INHIBITED_REGENERATION,
        mutations.MUT_NO_POTION_HEAL,
        mutations.MUT_DOPEY,
        mutations.MUT_CLUMSY,
        mutations.MUT_WEAK,
    },
    [pools.ARCANA] = {
        {
            mutations.MUT_NO_AIR_MAGIC,
            mutations.MUT_NO_FIRE_MAGIC,
            mutations.MUT_NO_ICE_MAGIC,
            mutations.MUT_NO_EARTH_MAGIC,
            mutations.MUT_NO_POISON_MAGIC,
        },
        {
            mutations.MUT_NO_TRANSMUTATION_MAGIC,
            mutations.MUT_NO_HEXES_MAGIC,
        },
        {
            mutations.MUT_NO_CONJURATION_MAGIC,
            mutations.MUT_NO_NECROMANCY_MAGIC,
            mutations.MUT_NO_SUMMONING_MAGIC,
            mutations.MUT_NO_TRANSLOCATION_MAGIC,
        },
    },
}

return variants

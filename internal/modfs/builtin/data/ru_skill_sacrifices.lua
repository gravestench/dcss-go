-- Only these Ru mutations remove a named skill. The same relation decides
-- whether a species that cannot train that skill should see the offer.
local mutations = require("ids.mutations")
local skills = require("ids.pinned_skills")

local sacrificed = {
    [mutations.MUT_NO_AIR_MAGIC] = skills.SK_AIR_MAGIC,
    [mutations.MUT_NO_FIRE_MAGIC] = skills.SK_FIRE_MAGIC,
    [mutations.MUT_NO_EARTH_MAGIC] = skills.SK_EARTH_MAGIC,
    [mutations.MUT_NO_ICE_MAGIC] = skills.SK_ICE_MAGIC,
    [mutations.MUT_NO_POISON_MAGIC] = skills.SK_POISON_MAGIC,
    [mutations.MUT_NO_HEXES_MAGIC] = skills.SK_HEXES,
    [mutations.MUT_NO_TRANSLOCATION_MAGIC] = skills.SK_TRANSLOCATIONS,
    [mutations.MUT_NO_TRANSMUTATION_MAGIC] = skills.SK_TRANSMUTATIONS,
    [mutations.MUT_NO_CONJURATION_MAGIC] = skills.SK_CONJURATIONS,
    [mutations.MUT_NO_NECROMANCY_MAGIC] = skills.SK_NECROMANCY,
    [mutations.MUT_NO_SUMMONING_MAGIC] = skills.SK_SUMMONINGS,
    [mutations.MUT_NO_DODGING] = skills.SK_DODGING,
    [mutations.MUT_NO_ARMOUR_SKILL] = skills.SK_ARMOUR,
    [mutations.MUT_NO_ARTIFICE] = skills.SK_EVOCATIONS,
    [mutations.MUT_NO_STEALTH] = skills.SK_STEALTH,
}

return sacrificed

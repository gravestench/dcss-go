-- Named random streams keep one domain from perturbing another domain’s replay sequence.

-- Named persisted RNG streams used by Lua policies.
local streams = {
    ACQUIREMENT = "acquirement",
    BRANCH_SCHEDULE = "branch_schedule",
    BANDS = "bands",
    CLOUDS = "clouds",
    FOG_MACHINES = "fog_machines",
    HELL_SERPENT = "hell_serpent",
    ITEM_GENERATION = "item_generation",
    MELEE = "melee",
    MONSTER_HP = "monster_hp",
    MONSTER_TRAITS = "monster_traits",
    MONSTER_SPELL = "monster_spell",
    PAN_LORD = "pan_lord",
    MUTATION = "mutation",
    POTION = "potion",
    PLACEMENT = "placement",
    POPULATION_COUNT = "population-count",
    SHOP = "shop",
    SPELL = "spell",
    TRAPS = "traps",
    ZOT_OVERGROWN = "zot_overgrown",
    ORB_RUN = "orb_run",
    TEMPLE_PLAN = "temple_plan",
}

return streams

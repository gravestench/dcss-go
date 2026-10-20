-- Named random streams keep one domain from perturbing another domain’s replay sequence.

-- Named persisted RNG streams used by Lua policies.
local streams = {
    ACQUIREMENT = "acquirement",
    BRANCH_SCHEDULE = "branch_schedule",
    BANDS = "bands",
    CLOUDS = "clouds",
    ITEM_GENERATION = "item_generation",
    MELEE = "melee",
    MONSTER_HP = "monster_hp",
    MONSTER_SPELL = "monster_spell",
    MUTATION = "mutation",
    POTION = "potion",
    PLACEMENT = "placement",
    SHOP = "shop",
    SPELL = "spell",
    TRAPS = "traps",
}

return streams

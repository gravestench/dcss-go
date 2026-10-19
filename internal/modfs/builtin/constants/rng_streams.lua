-- Named random streams keep one domain from perturbing another domain’s replay sequence.

-- Named persisted RNG streams used by Lua policies.
local streams = {
    ACQUIREMENT = "acquirement",
    CLOUDS = "clouds",
    ITEM_GENERATION = "item_generation",
    MELEE = "melee",
    MONSTER_SPELL = "monster_spell",
    MUTATION = "mutation",
    SHOP = "shop",
    TRAPS = "traps",
}

return streams

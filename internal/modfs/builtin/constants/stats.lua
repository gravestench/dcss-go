-- The three attribute names are shared by character creation, damage, and status effects.

local stats = {
    STRENGTH = "strength",
    INTELLIGENCE = "intelligence",
    DEXTERITY = "dexterity",
}

stats.ORDER = {
    stats.STRENGTH,
    stats.INTELLIGENCE,
    stats.DEXTERITY,
}

return stats

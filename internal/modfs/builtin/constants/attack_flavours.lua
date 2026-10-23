-- Shared source attack-flavour IDs. A monster profile and its hit resolver
-- must use the same ID, including when a mod replaces the monster's Lua.
local flavours = {
    PLAIN = "AF_PLAIN",
    FIRE = "AF_FIRE",
    ACID = "AF_ACID",
    POISON = "AF_POISON",
    POISON_STRONG = "AF_POISON_STRONG",
    ELECTRICITY = "AF_ELEC",
    COLD = "AF_COLD",
    STICKY_FLAME = "AF_STICKY_FLAME",
    DRAIN = "AF_DRAIN",
    STEAL = "AF_STEAL",
    VAMPIRIC = "AF_VAMPIRIC",
    MUTATE = "AF_MUTATE",
    CHAOTIC = "AF_CHAOTIC",
}

return flavours

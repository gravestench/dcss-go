-- The source's six low-intensity ugly-thing colours are body archetypes.
-- Their bright partners belong to very ugly things. A DES adjective uses
-- the human name, while rendering uses the source terminal colour token.
local flavours = require("constants.attack_flavours")
local resistance = require("constants.resistance_ids")

local colours = {
    {
        name = "red",
        low = "RED",
        high = "LIGHTRED",
        flavour = flavours.FIRE,
        very_flavour = flavours.STICKY_FLAME,
        resistance = resistance.FIRE,
        sticky_immune = true,
    },

    {
        name = "brown",
        low = "BROWN",
        high = "YELLOW",
        flavour = flavours.ACID,
        resistance = resistance.ACID,
    },

    {
        name = "green",
        low = "GREEN",
        high = "LIGHTGREEN",
        flavour = flavours.POISON,
        very_flavour = flavours.POISON_STRONG,
        resistance = resistance.POISON,
    },

    {
        name = "cyan",
        low = "CYAN",
        high = "LIGHTCYAN",
        flavour = flavours.ELECTRICITY,
        resistance = resistance.ELECTRICITY,
    },

    {
        name = "purple",
        low = "MAGENTA",
        high = "LIGHTMAGENTA",
        flavour = flavours.PLAIN,
        magenta_damage = true,
    },

    {
        name = "white",
        low = "LIGHTGREY",
        high = "WHITE",
        flavour = flavours.COLD,
        resistance = resistance.COLD,
    },
}

return colours

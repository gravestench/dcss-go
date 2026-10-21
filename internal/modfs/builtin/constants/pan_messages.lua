-- Pan messages originate in the source vault epilogues. Keep them separate
-- from map declarations so the region entry policy can present them once.
local messages = {
    HOLY_RUNE_WARNING = "The tension of great conflict fills the air!\n" ..
        "The demonic rune of Zot may be found here.",
    DEMONIC_RUNE_WARNING = "A powerful Pandemonium lord resides here.\n" ..
        "It guards the demonic rune of Zot.",
    BAZAAR_RUNE_WARNING = "A powerful Pandemonium lord resides here.\n" ..
        "It is willing to make a deal for the demonic rune of Zot.",
    LORDS = {
        MNOLEG = {
            name = "Mnoleg",
            warning = "The air here is shimmering with an eerie glow.",
            rune = "glowing",
        },

        LOM_LOBON = {
            name = "Lom Lobon",
            warning = "You sense a powerful magical presence. It is not pleased.",
            rune = "magical",
        },

        CEREBOV = {
            name = "Cerebov",
            warning = "Searing heat pours from the floors and walls of this place.",
            rune = "fiery",
        },

        GLOORX_VLOQ = {
            name = "Gloorx Vloq",
            warning = "Shadowy figures dance across your vision.",
            rune = "dark",
        },
    },
}

return messages

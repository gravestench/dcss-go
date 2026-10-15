-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2059

local categories = require("constants.catalog")

local definition = {
    id = "MST_JOSEPHINE",
    slots = {
        -- Source line: 2061
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2062
        {
            spell_id = "SPELL_GHOSTLY_FIREBALL",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2063
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1762

local categories = require("constants.catalog")

local definition = {
    id = "MST_MENNAS",
    slots = {
        -- Source line: 1764
        {
            spell_id = "SPELL_MASS_CONFUSION",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1765
        {
            spell_id = "SPELL_SILENCE",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1766
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

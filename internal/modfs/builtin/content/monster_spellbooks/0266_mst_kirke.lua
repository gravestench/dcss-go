-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2102

local categories = require("constants.catalog")

local definition = {
    id = "MST_KIRKE",
    slots = {
        -- Source line: 2104
        {
            spell_id = "SPELL_PORKALATOR",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2105
        {
            spell_id = "SPELL_SLOW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2106
        {
            spell_id = "SPELL_MONSTROUS_MENAGERIE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2107
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 113

local categories = require("constants.catalog")

local definition = {
    id = "MST_SATYR",
    slots = {
        -- Source line: 115
        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 25,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
        -- Source line: 116
        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 32,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 117
        {
            spell_id = "SPELL_SLEEP",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1092

local categories = require("constants.catalog")

local definition = {
    id = "MST_SALAMANDER_TYRANT",
    slots = {
        -- Source line: 1094
        {
            spell_id = "SPELL_ERUPTION",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1095
        {
            spell_id = "SPELL_PYROCLASTIC_SURGE",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1096
        {
            spell_id = "SPELL_WEAKENING_GAZE",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_INSTANT",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

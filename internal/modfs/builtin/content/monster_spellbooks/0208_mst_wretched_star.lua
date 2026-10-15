-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1596

local categories = require("constants.catalog")

local definition = {
    id = "MST_WRETCHED_STAR",
    slots = {
        -- Source line: 1598
        {
            spell_id = "SPELL_FORCE_LANCE",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1599
        {
            spell_id = "SPELL_CORRUPTING_PULSE",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

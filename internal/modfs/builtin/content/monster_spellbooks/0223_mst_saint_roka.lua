-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1734

local categories = require("constants.catalog")

local definition = {
    id = "MST_SAINT_ROKA",
    slots = {
        -- Source line: 1736
        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 100,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
        -- Source line: 1737
        {
            spell_id = "SPELL_SMITING",
            frequency = 64,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

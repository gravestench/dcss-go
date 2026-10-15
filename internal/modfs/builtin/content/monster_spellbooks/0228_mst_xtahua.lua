-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1778

local categories = require("constants.catalog")

local definition = {
    id = "MST_XTAHUA",
    slots = {
        -- Source line: 1780
        {
            spell_id = "SPELL_SEARING_BREATH",
            frequency = 62,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 1782
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 18,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

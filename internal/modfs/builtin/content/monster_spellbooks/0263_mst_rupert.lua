-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2076

local categories = require("constants.catalog")

local definition = {
    id = "MST_RUPERT",
    slots = {
        -- Source line: 2078
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 16,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
        -- Source line: 2079
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 16,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
        -- Source line: 2080
        {
            spell_id = "SPELL_BERSERKER_RAGE",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

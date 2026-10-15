-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1973

local categories = require("constants.catalog")

local definition = {
    id = "MST_GRINDER",
    slots = {
        -- Source line: 1975
        {
            spell_id = "SPELL_PAIN",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1976
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1977
        {
            spell_id = "SPELL_BLINK",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

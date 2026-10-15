-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 765

local categories = require("constants.catalog")

local definition = {
    id = "MST_TITAN",
    slots = {
        -- Source line: 767
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 768
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 769
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

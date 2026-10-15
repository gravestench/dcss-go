-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 482

local categories = require("constants.catalog")

local definition = {
    id = "MST_IMPERIAL_MYRMIDON",
    slots = {
        -- Source line: 484
        {
            spell_id = "SPELL_SLOW",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 485
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 486
        {
            spell_id = "SPELL_AGONY_RANGE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

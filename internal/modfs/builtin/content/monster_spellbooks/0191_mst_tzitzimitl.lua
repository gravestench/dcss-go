-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1469

local categories = require("constants.catalog")

local definition = {
    id = "MST_TZITZIMITL",
    slots = {
        -- Source line: 1471
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1472
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1473
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

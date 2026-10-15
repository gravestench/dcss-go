-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1426

local categories = require("constants.catalog")

local definition = {
    id = "MST_CACODEMON",
    slots = {
        -- Source line: 1428
        {
            spell_id = "SPELL_ENERGY_BOLT",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1429
        {
            spell_id = "SPELL_SLOW",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1430
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1431
        {
            spell_id = "SPELL_MALMUTATE",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1432
        {
            spell_id = "SPELL_DIG",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

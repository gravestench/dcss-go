-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 549

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRACONIAN_SHIFTER",
    slots = {
        -- Source line: 551
        {
            spell_id = "SPELL_DIMENSION_ANCHOR",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 552
        {
            spell_id = "SPELL_BLINK_OTHER",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 553
        {
            spell_id = "SPELL_BLINK_RANGE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 554
        {
            spell_id = "SPELL_BLINK_ALLIES_ENCIRCLE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 555
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

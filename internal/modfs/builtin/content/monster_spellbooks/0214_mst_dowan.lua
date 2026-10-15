-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1646

local categories = require("constants.catalog")

local definition = {
    id = "MST_DOWAN",
    slots = {
        -- Source line: 1648
        {
            spell_id = "SPELL_THROW_FLAME",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1649
        {
            spell_id = "SPELL_THROW_FROST",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1650
        {
            spell_id = "SPELL_BLINK",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1651
        {
            spell_id = "SPELL_CORONA",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1652
        {
            spell_id = "SPELL_HASTE_OTHER",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1716

local categories = require("constants.catalog")

local definition = {
    id = "MST_BLORK",
    slots = {
        -- Source line: 1718
        {
            spell_id = "SPELL_CANTRIP",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1719
        {
            spell_id = "SPELL_MAGIC_DART",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1720
        {
            spell_id = "SPELL_THROW_FROST",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1721
        {
            spell_id = "SPELL_THROW_FLAME",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1722
        {
            spell_id = "SPELL_HASTE",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

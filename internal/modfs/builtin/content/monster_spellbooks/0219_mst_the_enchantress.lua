-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1693

local categories = require("constants.catalog")

local definition = {
    id = "MST_THE_ENCHANTRESS",
    slots = {
        -- Source line: 1695
        {
            spell_id = "SPELL_SLOW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1696
        {
            spell_id = "SPELL_DIMENSION_ANCHOR",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1697
        {
            spell_id = "SPELL_MASS_CONFUSION",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1698
        {
            spell_id = "SPELL_STRIP_WILLPOWER",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1699
        {
            spell_id = "SPELL_HASTE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1700
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

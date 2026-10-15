-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2205

local categories = require("constants.catalog")

local definition = {
    id = "MST_ERESHKIGAL",
    slots = {
        -- Source line: 2207
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2208
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2209
        {
            spell_id = "SPELL_SUMMON_TZITZIMITL",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2210
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2211
        {
            spell_id = "SPELL_SILENCE",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2212
        {
            spell_id = "SPELL_MAJOR_HEALING",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

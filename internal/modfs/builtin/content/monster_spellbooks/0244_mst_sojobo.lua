-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1910

local categories = require("constants.catalog")

local definition = {
    id = "MST_SOJOBO",
    slots = {
        -- Source line: 1912
        {
            spell_id = "SPELL_WIND_BLAST",
            frequency = 28,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1913
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1914
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1915
        {
            spell_id = "SPELL_AIR_ELEMENTALS",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1916
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

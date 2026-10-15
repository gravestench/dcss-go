-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1742

local categories = require("constants.catalog")

local definition = {
    id = "MST_GASTRONOK",
    slots = {
        -- Source line: 1744
        {
            spell_id = "SPELL_CANTRIP",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1745
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1746
        {
            spell_id = "SPELL_SUMMON_SMALL_MAMMAL",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1747
        {
            spell_id = "SPELL_SLOW",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1748
        {
            spell_id = "SPELL_SPRINT",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

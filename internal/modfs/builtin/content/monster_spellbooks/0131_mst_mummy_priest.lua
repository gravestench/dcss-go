-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1018

local categories = require("constants.catalog")

local definition = {
    id = "MST_MUMMY_PRIEST",
    slots = {
        -- Source line: 1020
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 12,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1021
        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 24,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1022
        {
            spell_id = "SPELL_SMITING",
            frequency = 12,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1023
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 12,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

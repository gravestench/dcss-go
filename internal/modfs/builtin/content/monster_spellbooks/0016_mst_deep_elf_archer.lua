-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 147

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_ARCHER",
    slots = {
        -- Source line: 149
        {
            spell_id = "SPELL_SLOW",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 150
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 151
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 152
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_SHORT_RANGE",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

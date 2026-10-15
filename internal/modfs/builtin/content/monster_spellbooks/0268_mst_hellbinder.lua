-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2118

local categories = require("constants.catalog")

local definition = {
    id = "MST_HELLBINDER",
    slots = {
        -- Source line: 2120
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2121
        {
            spell_id = "SPELL_SUMMON_GREATER_DEMON",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2122
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2123
        {
            spell_id = "SPELL_HASTE",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2124
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

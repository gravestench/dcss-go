-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 156

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_ELEMENTALIST",
    slots = {
        -- Source line: 158
        {
            spell_id = "SPELL_FREEZING_CLOUD",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 159
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 160
        {
            spell_id = "SPELL_AWAKEN_EARTH",
            frequency = 44,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 161
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 162
        {
            spell_id = "SPELL_HASTE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

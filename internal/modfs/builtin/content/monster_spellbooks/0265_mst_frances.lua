-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2093

local categories = require("constants.catalog")

local definition = {
    id = "MST_FRANCES",
    slots = {
        -- Source line: 2095
        {
            spell_id = "SPELL_THROW_ICICLE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2096
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2097
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2098
        {
            spell_id = "SPELL_HASTE",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

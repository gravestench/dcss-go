-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 999

local categories = require("constants.catalog")

local definition = {
    id = "MST_DREAD_LICH",
    slots = {
        -- Source line: 1001
        {
            spell_id = "SPELL_SUMMON_GREATER_DEMON",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1002
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1003
        {
            spell_id = "SPELL_HASTE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1004
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

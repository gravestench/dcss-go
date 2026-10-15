-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1705

local categories = require("constants.catalog")

local definition = {
    id = "MST_ILSUIW",
    slots = {
        -- Source line: 1707
        {
            spell_id = "SPELL_THROW_ICICLE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1708
        {
            spell_id = "SPELL_WATER_ELEMENTALS",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1709
        {
            spell_id = "SPELL_CALL_TIDE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1710
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1711
        {
            spell_id = "SPELL_BLINK",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

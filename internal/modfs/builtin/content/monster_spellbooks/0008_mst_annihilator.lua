-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 81

local categories = require("constants.catalog")

local definition = {
    id = "MST_ANNIHILATOR",
    slots = {
        -- Source line: 83
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 84
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 85
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 86
        {
            spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 87
        {
            spell_id = "SPELL_BLINK",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

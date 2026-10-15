-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1998

local categories = require("constants.catalog")

local definition = {
    id = "MST_ROXANNE",
    slots = {
        -- Source line: 2000
        {
            spell_id = "SPELL_BOLT_OF_MAGMA",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2001
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2002
        {
            spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2003
        {
            spell_id = "SPELL_BLINK_OTHER_CLOSE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

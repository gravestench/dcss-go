-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 522

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRACONIAN_SCORCHER",
    slots = {
        -- Source line: 524
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 525
        {
            spell_id = "SPELL_BOLT_OF_MAGMA",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 526
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 527
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 528
        {
            spell_id = "SPELL_CALL_DOWN_DAMNATION",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

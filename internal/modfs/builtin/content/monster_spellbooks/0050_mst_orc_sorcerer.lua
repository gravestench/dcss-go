-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 406

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORC_SORCERER",
    slots = {
        -- Source line: 408
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 409
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 410
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 411
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

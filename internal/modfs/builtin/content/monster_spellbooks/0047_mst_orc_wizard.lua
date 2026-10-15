-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 382

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORC_WIZARD",
    slots = {
        -- Source line: 384
        {
            spell_id = "SPELL_MAGIC_DART",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 385
        {
            spell_id = "SPELL_THROW_FLAME",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 386
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 387
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 9,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

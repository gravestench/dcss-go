-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 532

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRACONIAN_KNIGHT",
    slots = {
        -- Source line: 534
        {
            spell_id = "SPELL_THROW_ICICLE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 535
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 536
        {
            spell_id = "SPELL_HASTE",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 537
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

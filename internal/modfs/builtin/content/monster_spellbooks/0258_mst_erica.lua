-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2034

local categories = require("constants.catalog")

local definition = {
    id = "MST_ERICA",
    slots = {
        -- Source line: 2036
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2037
        {
            spell_id = "SPELL_FORCE_LANCE",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2038
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2039
        {
            spell_id = "SPELL_SLOW",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2040
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

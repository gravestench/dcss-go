-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 166

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_SORCERER",
    slots = {
        -- Source line: 168
        {
            spell_id = "SPELL_CORROSIVE_BOLT",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 169
        {
            spell_id = "SPELL_BANISHMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 170
        {
            spell_id = "SPELL_HASTE",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 171
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

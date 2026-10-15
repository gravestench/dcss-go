-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 943

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPHINX",
    slots = {
        -- Source line: 945
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 946
        {
            spell_id = "SPELL_SLOW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 947
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 948
        {
            spell_id = "SPELL_SMITING",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

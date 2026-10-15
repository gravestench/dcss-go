-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 979

local categories = require("constants.catalog")

local definition = {
    id = "MST_LICH",
    slots = {
        -- Source line: 981
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 982
        {
            spell_id = "SPELL_IOOD",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 983
        {
            spell_id = "SPELL_HASTE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 984
        {
            spell_id = "SPELL_SLOW",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 985
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

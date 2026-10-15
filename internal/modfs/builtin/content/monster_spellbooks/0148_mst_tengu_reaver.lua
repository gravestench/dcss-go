-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1151

local categories = require("constants.catalog")

local definition = {
    id = "MST_TENGU_REAVER",
    slots = {
        -- Source line: 1153
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1154
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1155
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1156
        {
            spell_id = "SPELL_CORROSIVE_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1157
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1158
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

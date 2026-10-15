-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1059

local categories = require("constants.catalog")

local definition = {
    id = "MST_NAGARAJA",
    slots = {
        -- Source line: 1061
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1062
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1063
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1064
        {
            spell_id = "SPELL_DIMENSION_ANCHOR",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1065
        {
            spell_id = "SPELL_HASTE",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

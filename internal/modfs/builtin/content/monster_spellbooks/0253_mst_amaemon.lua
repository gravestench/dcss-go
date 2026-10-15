-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1990

local categories = require("constants.catalog")

local definition = {
    id = "MST_AMAEMON",
    slots = {
        -- Source line: 1992
        {
            spell_id = "SPELL_CONCENTRATE_VENOM",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1993
        {
            spell_id = "SPELL_SUMMON_SCORPIONS",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

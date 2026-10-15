-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 308

local categories = require("constants.catalog")

local definition = {
    id = "MST_WIND_DRAKE",
    slots = {
        -- Source line: 310
        {
            spell_id = "SPELL_WIND_BLAST",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 311
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 29,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 312
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 29,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

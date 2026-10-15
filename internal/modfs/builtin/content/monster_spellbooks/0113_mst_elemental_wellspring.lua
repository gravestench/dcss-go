-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 868

local categories = require("constants.catalog")

local definition = {
    id = "MST_ELEMENTAL_WELLSPRING",
    slots = {
        -- Source line: 870
        {
            spell_id = "SPELL_PRIMAL_WAVE",
            frequency = 65,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 871
        {
            spell_id = "SPELL_WATER_ELEMENTALS",
            frequency = 65,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

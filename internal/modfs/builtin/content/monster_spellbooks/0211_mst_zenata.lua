-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1623

local categories = require("constants.catalog")

local definition = {
    id = "MST_ZENATA",
    slots = {
        -- Source line: 1625
        {
            spell_id = "SPELL_RESONANCE_STRIKE",
            frequency = 40,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1626
        {
            spell_id = "SPELL_SHEZAS_DANCE",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

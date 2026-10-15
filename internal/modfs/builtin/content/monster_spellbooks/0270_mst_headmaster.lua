-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2135

local categories = require("constants.catalog")

local definition = {
    id = "MST_HEADMASTER",
    slots = {
        -- Source line: 2137
        {
            spell_id = "SPELL_SUMMON_MANA_VIPER",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2138
        {
            spell_id = "SPELL_DIMENSION_ANCHOR",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2139
        {
            spell_id = "SPELL_BLINK_CLOSE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2140
        {
            spell_id = "SPELL_ENERGY_BOLT",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

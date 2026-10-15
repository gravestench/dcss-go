-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1881

local categories = require("constants.catalog")

local definition = {
    id = "MST_KHUFU",
    slots = {
        -- Source line: 1883
        {
            spell_id = "SPELL_SMITING",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1884
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1885
        {
            spell_id = "SPELL_SUMMON_EMPEROR_SCORPIONS",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1886
        {
            spell_id = "SPELL_SUMMON_SCARABS",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1887
        {
            spell_id = "SPELL_BLINK",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

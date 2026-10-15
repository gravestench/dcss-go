-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1027

local categories = require("constants.catalog")

local definition = {
    id = "MST_ROYAL_MUMMY",
    slots = {
        -- Source line: 1029
        {
            spell_id = "SPELL_SMITING",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1030
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1031
        {
            spell_id = "SPELL_SUMMON_EMPEROR_SCORPIONS",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1032
        {
            spell_id = "SPELL_SUMMON_SCARABS",
            frequency = 26,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

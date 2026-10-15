-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2254

local categories = require("constants.catalog")

local definition = {
    id = "MST_GLOORX_VLOQ",
    slots = {
        -- Source line: 2256
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2257
        {
            spell_id = "SPELL_MIASMA_BREATH",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2258
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2259
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2260
        {
            spell_id = "SPELL_SUMMON_EXECUTIONERS",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

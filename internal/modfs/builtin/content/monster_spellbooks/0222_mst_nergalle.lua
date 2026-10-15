-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1726

local categories = require("constants.catalog")

local definition = {
    id = "MST_NERGALLE",
    slots = {
        -- Source line: 1728
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1729
        {
            spell_id = "SPELL_SUMMON_SPECTRAL_ORCS",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1730
        {
            spell_id = "SPELL_HASTE_OTHER",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

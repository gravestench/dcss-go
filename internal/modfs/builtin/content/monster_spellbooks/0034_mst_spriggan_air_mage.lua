-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 287

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPRIGGAN_AIR_MAGE",
    slots = {
        -- Source line: 289
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 290
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 32,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 291
        {
            spell_id = "SPELL_REPEL_MISSILES",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

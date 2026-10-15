-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 354

local categories = require("constants.catalog")

local definition = {
    id = "MST_MERFOLK_AQUAMANCER",
    slots = {
        -- Source line: 356
        {
            spell_id = "SPELL_PRIMAL_WAVE",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 357
        {
            spell_id = "SPELL_STEAM_BALL",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 358
        {
            spell_id = "SPELL_THROW_ICICLE",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 359
        {
            spell_id = "SPELL_BLINK",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

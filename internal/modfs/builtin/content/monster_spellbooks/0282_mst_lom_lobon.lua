-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2235

local categories = require("constants.catalog")

local definition = {
    id = "MST_LOM_LOBON",
    slots = {
        -- Source line: 2237
        {
            spell_id = "SPELL_CONJURE_BALL_LIGHTNING",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2238
        {
            spell_id = "SPELL_GLACIATE",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2239
        {
            spell_id = "SPELL_POLAR_VORTEX",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2240
        {
            spell_id = "SPELL_MAJOR_HEALING",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2241
        {
            spell_id = "SPELL_BLINK_RANGE",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

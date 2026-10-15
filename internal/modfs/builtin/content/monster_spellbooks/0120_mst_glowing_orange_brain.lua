-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 918

local categories = require("constants.catalog")

local definition = {
    id = "MST_GLOWING_ORANGE_BRAIN",
    slots = {
        -- Source line: 920
        {
            spell_id = "SPELL_BRAIN_FEED",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 921
        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 922
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 923
        {
            spell_id = "SPELL_MASS_CONFUSION",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 924
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

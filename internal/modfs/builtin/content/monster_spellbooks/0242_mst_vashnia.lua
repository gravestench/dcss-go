-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1892

local categories = require("constants.catalog")

local definition = {
    id = "MST_VASHNIA",
    slots = {
        -- Source line: 1894
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1895
        {
            spell_id = "SPELL_PORTAL_PROJECTILE",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1896
        {
            spell_id = "SPELL_BLINK_OTHER",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
        -- Source line: 1897
        {
            spell_id = "SPELL_BLINK_ALLIES_AWAY",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1898
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

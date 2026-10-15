-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1069

local categories = require("constants.catalog")

local definition = {
    id = "MST_NAGA_SHARPSHOOTER",
    slots = {
        -- Source line: 1071
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1072
        {
            spell_id = "SPELL_PORTAL_PROJECTILE",
            frequency = 59,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

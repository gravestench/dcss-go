-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1076

local categories = require("constants.catalog")

local definition = {
    id = "MST_NAGA_RITUALIST",
    slots = {
        -- Source line: 1078
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1079
        {
            spell_id = "SPELL_OLGREBS_TOXIC_RADIANCE",
            frequency = 30,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1080
        {
            spell_id = "SPELL_VIRULENCE",
            frequency = 35,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

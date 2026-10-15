-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2128

local categories = require("constants.catalog")

local definition = {
    id = "MST_CLOUD_MAGE",
    slots = {
        -- Source line: 2130
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 25,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2131
        {
            spell_id = "SPELL_POLAR_VORTEX",
            frequency = 40,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

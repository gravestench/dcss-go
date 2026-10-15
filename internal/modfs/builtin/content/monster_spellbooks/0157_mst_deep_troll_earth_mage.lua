-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1222

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_TROLL_EARTH_MAGE",
    slots = {
        -- Source line: 1224
        {
            spell_id = "SPELL_LRD",
            frequency = 31,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1225
        {
            spell_id = "SPELL_DIG",
            frequency = 31,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

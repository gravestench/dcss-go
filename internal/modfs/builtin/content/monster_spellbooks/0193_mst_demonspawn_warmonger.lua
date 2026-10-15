-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1485

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEMONSPAWN_WARMONGER",
    slots = {
        -- Source line: 1487
        {
            spell_id = "SPELL_SAP_MAGIC",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1488
        {
            spell_id = "SPELL_HASTE_OTHER",
            frequency = 32,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

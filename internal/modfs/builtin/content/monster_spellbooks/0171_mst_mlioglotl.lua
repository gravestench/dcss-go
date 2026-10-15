-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1323

local categories = require("constants.catalog")

local definition = {
    id = "MST_MLIOGLOTL",
    slots = {
        -- Source line: 1325
        {
            spell_id = "SPELL_MIGHT",
            frequency = 18,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 1326
        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1327
        {
            spell_id = "SPELL_CORRUPT_LOCALE",
            frequency = 36,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

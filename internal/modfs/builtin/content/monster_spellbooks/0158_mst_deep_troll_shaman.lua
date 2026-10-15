-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1229

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_TROLL_SHAMAN",
    slots = {
        -- Source line: 1231
        {
            spell_id = "SPELL_HASTE_OTHER",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1232
        {
            spell_id = "SPELL_MIGHT_OTHER",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

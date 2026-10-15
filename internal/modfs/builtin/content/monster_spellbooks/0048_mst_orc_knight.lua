-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 391

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORC_KNIGHT",
    slots = {
        -- Source line: 393
        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

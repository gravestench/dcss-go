-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 903

local categories = require("constants.catalog")

local definition = {
    id = "MST_SHINING_EYE",
    slots = {
        -- Source line: 905
        {
            spell_id = "SPELL_MALMUTATE",
            frequency = 57,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

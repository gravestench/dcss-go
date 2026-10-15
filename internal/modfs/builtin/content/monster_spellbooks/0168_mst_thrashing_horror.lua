-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1305

local categories = require("constants.catalog")

local definition = {
    id = "MST_THRASHING_HORROR",
    slots = {
        -- Source line: 1307
        {
            spell_id = "SPELL_MIGHT",
            frequency = 59,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

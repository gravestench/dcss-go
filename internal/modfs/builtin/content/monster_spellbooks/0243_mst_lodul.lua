-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1903

local categories = require("constants.catalog")

local definition = {
    id = "MST_LODUL",
    slots = {
        -- Source line: 1905
        {
            spell_id = "SPELL_CALL_DOWN_LIGHTNING",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 673

local categories = require("constants.catalog")

local definition = {
    id = "MST_MOTH_OF_WRATH",
    slots = {
        -- Source line: 675
        {
            spell_id = "SPELL_BERSERK_OTHER",
            frequency = 66,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

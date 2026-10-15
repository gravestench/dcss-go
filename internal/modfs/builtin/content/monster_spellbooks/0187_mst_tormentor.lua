-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1442

local categories = require("constants.catalog")

local definition = {
    id = "MST_TORMENTOR",
    slots = {
        -- Source line: 1444
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 29,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

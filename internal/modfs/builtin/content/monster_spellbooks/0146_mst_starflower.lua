-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1136

local categories = require("constants.catalog")

local definition = {
    id = "MST_STARFLOWER",
    slots = {
        -- Source line: 1138
        {
            spell_id = "SPELL_HARPOON_SHOT",
            frequency = 80,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

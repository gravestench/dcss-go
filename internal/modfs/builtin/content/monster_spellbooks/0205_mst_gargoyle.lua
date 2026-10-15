-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1577

local categories = require("constants.catalog")

local definition = {
    id = "MST_GARGOYLE",
    slots = {
        -- Source line: 1579
        {
            spell_id = "SPELL_STONE_ARROW",
            frequency = 56,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

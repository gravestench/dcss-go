-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 627

local categories = require("constants.catalog")

local definition = {
    id = "MST_DART_SLUG",
    slots = {
        -- Source line: 629
        {
            spell_id = "SPELL_SLUG_DART",
            frequency = 60,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 201

local categories = require("constants.catalog")

local definition = {
    id = "MST_THORN_HUNTER",
    slots = {
        -- Source line: 203
        {
            spell_id = "SPELL_THORN_VOLLEY",
            frequency = 43,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 204
        {
            spell_id = "SPELL_WALL_OF_BRAMBLES",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

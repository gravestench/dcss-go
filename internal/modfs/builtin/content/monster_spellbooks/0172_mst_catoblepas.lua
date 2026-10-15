-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1332

local categories = require("constants.catalog")

local definition = {
    id = "MST_CATOBLEPAS",
    slots = {
        -- Source line: 1334
        {
            spell_id = "SPELL_PETRIFYING_CLOUD",
            frequency = 41,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

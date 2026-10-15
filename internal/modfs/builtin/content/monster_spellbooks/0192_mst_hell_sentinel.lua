-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1477

local categories = require("constants.catalog")

local definition = {
    id = "MST_HELL_SENTINEL",
    slots = {
        -- Source line: 1479
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 28,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1480
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 14,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

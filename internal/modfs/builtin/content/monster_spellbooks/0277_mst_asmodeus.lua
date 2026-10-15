-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2190

local categories = require("constants.catalog")

local definition = {
    id = "MST_ASMODEUS",
    slots = {
        -- Source line: 2192
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2193
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2194
        {
            spell_id = "SPELL_FIRE_SUMMON",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

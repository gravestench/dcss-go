-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2175

local categories = require("constants.catalog")

local definition = {
    id = "MST_PSYCHE",
    slots = {
        -- Source line: 2177
        {
            spell_id = "SPELL_CANTRIP",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2178
        {
            spell_id = "SPELL_POLYMORPH",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2179
        {
            spell_id = "SPELL_CHAIN_OF_CHAOS",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2180
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

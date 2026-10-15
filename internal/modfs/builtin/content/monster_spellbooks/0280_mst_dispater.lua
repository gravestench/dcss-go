-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2216

local categories = require("constants.catalog")

local definition = {
    id = "MST_DISPATER",
    slots = {
        -- Source line: 2218
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2219
        {
            spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2220
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2221
        {
            spell_id = "SPELL_SUMMON_HELL_SENTINEL",
            frequency = 26,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2225

local categories = require("constants.catalog")

local definition = {
    id = "MST_MNOLEG",
    slots = {
        -- Source line: 2227
        {
            spell_id = "SPELL_MALIGN_GATEWAY",
            frequency = 27,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2228
        {
            spell_id = "SPELL_SUMMON_EYEBALLS",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2229
        {
            spell_id = "SPELL_SUMMON_HORRIBLE_THINGS",
            frequency = 27,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2230
        {
            spell_id = "SPELL_CALL_OF_CHAOS",
            frequency = 27,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2231
        {
            spell_id = "SPELL_DIG",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

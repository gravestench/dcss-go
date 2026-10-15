-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1417

local categories = require("constants.catalog")

local definition = {
    id = "MST_BLIZZARD_DEMON",
    slots = {
        -- Source line: 1419
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1420
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1421
        {
            spell_id = "SPELL_FREEZING_CLOUD",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1422
        {
            spell_id = "SPELL_AIRSTRIKE",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

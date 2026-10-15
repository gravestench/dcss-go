-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1931

local categories = require("constants.catalog")

local definition = {
    id = "MST_MARA",
    slots = {
        -- Source line: 1933
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 14,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1934
        {
            spell_id = "SPELL_FAKE_MARA_SUMMON",
            frequency = 14,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1935
        {
            spell_id = "SPELL_SUMMON_ILLUSION",
            frequency = 14,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1936
        {
            spell_id = "SPELL_BLINK",
            frequency = 29,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

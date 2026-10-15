-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1921

local categories = require("constants.catalog")

local definition = {
    id = "MST_AZRAEL",
    slots = {
        -- Source line: 1923
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1924
        {
            spell_id = "SPELL_STICKY_FLAME_RANGE",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1925
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1926
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1927
        {
            spell_id = "SPELL_CALL_DOWN_DAMNATION",
            frequency = 13,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

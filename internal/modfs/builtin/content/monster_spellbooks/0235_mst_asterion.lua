-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1834

local categories = require("constants.catalog")

local definition = {
    id = "MST_ASTERION",
    slots = {
        -- Source line: 1836
        {
            spell_id = "SPELL_MAJOR_DESTRUCTION",
            frequency = 11,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1837
        {
            spell_id = "SPELL_GREATER_SERVANT_MAKHLEB",
            frequency = 22,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1838
        {
            spell_id = "SPELL_HASTE",
            frequency = 32,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

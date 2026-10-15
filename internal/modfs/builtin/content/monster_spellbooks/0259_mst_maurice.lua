-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2044

local categories = require("constants.catalog")

local definition = {
    id = "MST_MAURICE",
    slots = {
        -- Source line: 2046
        {
            spell_id = "SPELL_SPRINT",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2047
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2048
        {
            spell_id = "SPELL_BLINK",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

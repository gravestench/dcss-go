-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 441

local categories = require("constants.catalog")

local definition = {
    id = "MST_HELL_KNIGHT",
    slots = {
        -- Source line: 443
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 17,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 444
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_PRIEST",
                "MON_SPELL_EMERGENCY",
            },
        },
        -- Source line: 445
        {
            spell_id = "SPELL_HASTE",
            frequency = 26,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

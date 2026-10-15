-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1110

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRONBOUND_THUNDERHULK",
    slots = {
        -- Source line: 1112
        {
            spell_id = "SPELL_CALL_DOWN_LIGHTNING",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1113
        {
            spell_id = "SPELL_BLINK_RANGE",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

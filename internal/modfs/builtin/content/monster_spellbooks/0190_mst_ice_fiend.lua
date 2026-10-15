-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1462

local categories = require("constants.catalog")

local definition = {
    id = "MST_ICE_FIEND",
    slots = {
        -- Source line: 1464
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 46,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1465
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 23,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

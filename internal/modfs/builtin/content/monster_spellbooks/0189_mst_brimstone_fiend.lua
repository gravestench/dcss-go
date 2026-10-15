-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1455

local categories = require("constants.catalog")

local definition = {
    id = "MST_BRIMSTONE_FIEND",
    slots = {
        -- Source line: 1457
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 34,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1458
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 17,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2111

local categories = require("constants.catalog")

local definition = {
    id = "MST_DONALD",
    slots = {
        -- Source line: 2113
        {
            spell_id = "SPELL_MIGHT",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2114
        {
            spell_id = "SPELL_HASTE",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

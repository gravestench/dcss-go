-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1873

local categories = require("constants.catalog")

local definition = {
    id = "MST_MENKAURE",
    slots = {
        -- Source line: 1875
        {
            spell_id = "SPELL_PAIN",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1876
        {
            spell_id = "SPELL_HASTE",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1877
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

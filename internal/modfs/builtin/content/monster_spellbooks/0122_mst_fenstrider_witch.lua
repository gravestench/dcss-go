-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 935

local categories = require("constants.catalog")

local definition = {
    id = "MST_FENSTRIDER_WITCH",
    slots = {
        -- Source line: 937
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 938
        {
            spell_id = "SPELL_AGONY",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 939
        {
            spell_id = "SPELL_HURL_SLUDGE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

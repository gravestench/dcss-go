-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 701

local categories = require("constants.catalog")

local definition = {
    id = "MST_CURSE_TOE",
    slots = {
        -- Source line: 703
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 26,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 704
        {
            spell_id = "SPELL_SUMMON_MUSHROOMS",
            frequency = 39,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

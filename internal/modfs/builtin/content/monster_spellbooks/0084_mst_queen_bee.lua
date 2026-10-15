-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 660

local categories = require("constants.catalog")

local definition = {
    id = "MST_QUEEN_BEE",
    slots = {
        -- Source line: 662
        {
            spell_id = "SPELL_BERSERK_OTHER",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 663
        {
            spell_id = "SPELL_BERSERK_OTHER",
            frequency = 75,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

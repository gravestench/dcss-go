-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 687

local categories = require("constants.catalog")

local definition = {
    id = "MST_ANCIENT_CHAMPION",
    slots = {
        -- Source line: 689
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 21,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 690
        {
            spell_id = "SPELL_HASTE",
            frequency = 21,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

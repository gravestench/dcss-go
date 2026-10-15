-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 875

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRON_ELEMENTAL",
    slots = {
        -- Source line: 877
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 878
        {
            spell_id = "SPELL_METAL_SPLINTERS",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 879
        {
            spell_id = "SPELL_SLOW",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

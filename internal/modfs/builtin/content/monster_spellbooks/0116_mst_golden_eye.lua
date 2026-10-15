-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 890

local categories = require("constants.catalog")

local definition = {
    id = "MST_GOLDEN_EYE",
    slots = {
        -- Source line: 892
        {
            spell_id = "SPELL_CONFUSION_GAZE",
            frequency = 100,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_INSTANT",
            },
        },
        -- Source line: 893
        {
            spell_id = "SPELL_BLINK",
            frequency = 29,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

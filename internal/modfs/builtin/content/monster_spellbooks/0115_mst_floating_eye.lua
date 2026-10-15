-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 884

local categories = require("constants.catalog")

local definition = {
    id = "MST_FLOATING_EYE",
    slots = {
        -- Source line: 886
        {
            spell_id = "SPELL_PARALYSIS_GAZE",
            frequency = 80,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_INSTANT",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

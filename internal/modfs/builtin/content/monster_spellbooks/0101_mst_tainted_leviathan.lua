-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 781

local categories = require("constants.catalog")

local definition = {
    id = "MST_TAINTED_LEVIATHAN",
    slots = {
        -- Source line: 783
        {
            spell_id = "SPELL_MESMERISE",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

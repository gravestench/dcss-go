-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1215

local categories = require("constants.catalog")

local definition = {
    id = "MST_SHOCK_SERPENT",
    slots = {
        -- Source line: 1217
        {
            spell_id = "SPELL_ELECTRICAL_BOLT",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

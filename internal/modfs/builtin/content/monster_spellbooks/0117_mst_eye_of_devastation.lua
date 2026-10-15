-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 897

local categories = require("constants.catalog")

local definition = {
    id = "MST_EYE_OF_DEVASTATION",
    slots = {
        -- Source line: 899
        {
            spell_id = "SPELL_ENERGY_BOLT",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

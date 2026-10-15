-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1612

local categories = require("constants.catalog")

local definition = {
    id = "MST_WALKING_TOME",
    slots = {
        -- Source line: 1614
        {
            spell_id = "SPELL_CONJURE_LIVING_SPELLS",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

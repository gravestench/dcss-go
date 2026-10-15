-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 640

local categories = require("constants.catalog")

local definition = {
    id = "MST_WORLDBINDER",
    slots = {
        -- Source line: 642
        {
            spell_id = "SPELL_FORCEFUL_INVITATION",
            frequency = 58,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

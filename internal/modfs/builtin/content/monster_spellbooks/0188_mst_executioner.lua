-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1449

local categories = require("constants.catalog")

local definition = {
    id = "MST_EXECUTIONER",
    slots = {
        -- Source line: 1451
        {
            spell_id = "SPELL_HASTE",
            frequency = 41,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 74

local categories = require("constants.catalog")

local definition = {
    id = "MST_SCREAMER",
    slots = {
        -- Source line: 76
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 40,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

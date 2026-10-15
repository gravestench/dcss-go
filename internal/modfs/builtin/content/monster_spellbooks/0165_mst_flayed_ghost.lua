-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1284

local categories = require("constants.catalog")

local definition = {
    id = "MST_FLAYED_GHOST",
    slots = {
        -- Source line: 1286
        {
            spell_id = "SPELL_FLAY",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

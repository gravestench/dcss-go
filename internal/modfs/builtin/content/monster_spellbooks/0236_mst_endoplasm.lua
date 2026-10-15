-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1843

local categories = require("constants.catalog")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        -- Source line: 1845
        {
            spell_id = "SPELL_FREEZE",
            frequency = 70,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

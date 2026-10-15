-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 52

local categories = require("constants.catalog")

local definition = {
    id = "MST_ZAPPER",
    slots = {
        -- Source line: 54
        {
            spell_id = "SPELL_ELECTRICAL_BOLT",
            frequency = 100,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

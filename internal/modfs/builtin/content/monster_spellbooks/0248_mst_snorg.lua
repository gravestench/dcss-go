-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1950

local categories = require("constants.catalog")

local definition = {
    id = "MST_SNORG",
    slots = {
        -- Source line: 1952
        {
            spell_id = "SPELL_BERSERKER_RAGE",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

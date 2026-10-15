-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 587

local categories = require("constants.catalog")

local definition = {
    id = "MST_CULICIVORA",
    slots = {
        -- Source line: 589
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 40,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

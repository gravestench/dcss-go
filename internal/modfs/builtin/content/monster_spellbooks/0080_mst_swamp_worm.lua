-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 633

local categories = require("constants.catalog")

local definition = {
    id = "MST_SWAMP_WORM",
    slots = {
        -- Source line: 635
        {
            spell_id = "SPELL_HARPOON_SHOT",
            frequency = 80,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

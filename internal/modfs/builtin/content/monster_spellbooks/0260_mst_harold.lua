-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2052

local categories = require("constants.catalog")

local definition = {
    id = "MST_HAROLD",
    slots = {
        -- Source line: 2054
        {
            spell_id = "SPELL_HARPOON_SHOT",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2055
        {
            spell_id = "SPELL_SENTINEL_MARK",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 773

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRON_GIANT",
    slots = {
        -- Source line: 775
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 776
        {
            spell_id = "SPELL_HARPOON_SHOT",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 777
        {
            spell_id = "SPELL_THROW_ALLY",
            frequency = 36,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

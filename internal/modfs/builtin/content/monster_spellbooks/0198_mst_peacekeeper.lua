-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1523

local categories = require("constants.catalog")

local definition = {
    id = "MST_PEACEKEEPER",
    slots = {
        -- Source line: 1525
        {
            spell_id = "SPELL_THROW_BARBS",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 1526
        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 25,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

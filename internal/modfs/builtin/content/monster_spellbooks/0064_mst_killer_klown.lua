-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 513

local categories = require("constants.catalog")

local definition = {
    id = "MST_KILLER_KLOWN",
    slots = {
        -- Source line: 515
        {
            spell_id = "SPELL_BLINK",
            frequency = 29,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 516
        {
            spell_id = "SPELL_THROW_PIE",
            frequency = 24,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

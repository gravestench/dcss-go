-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 738

local categories = require("constants.catalog")

local definition = {
    id = "MST_BOULDER_BEETLE",
    slots = {
        -- Source line: 740
        {
            spell_id = "SPELL_ROLL",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 741
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 20,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

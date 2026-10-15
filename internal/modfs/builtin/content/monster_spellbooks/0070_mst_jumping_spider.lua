-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 568

local categories = require("constants.catalog")

local definition = {
    id = "MST_JUMPING_SPIDER",
    slots = {
        -- Source line: 570
        {
            spell_id = "SPELL_BLINK_CLOSE",
            frequency = 29,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 571
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 29,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

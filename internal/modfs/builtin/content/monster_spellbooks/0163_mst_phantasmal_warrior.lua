-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1271

local categories = require("constants.catalog")

local definition = {
    id = "MST_PHANTASMAL_WARRIOR",
    slots = {
        -- Source line: 1273
        {
            spell_id = "SPELL_BLINK_CLOSE",
            frequency = 67,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

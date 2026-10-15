-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 600

local categories = require("constants.catalog")

local definition = {
    id = "MST_FIRE_CRAB",
    slots = {
        -- Source line: 602
        {
            spell_id = "SPELL_FLAMING_CLOUD",
            frequency = 62,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

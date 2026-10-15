-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 679

local categories = require("constants.catalog")

local definition = {
    id = "MST_SUN_MOTH",
    slots = {
        -- Source line: 681
        {
            spell_id = "SPELL_STICKY_FLAME_RANGE",
            frequency = 20,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 682
        {
            spell_id = "SPELL_ENERGY_BOLT",
            frequency = 20,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

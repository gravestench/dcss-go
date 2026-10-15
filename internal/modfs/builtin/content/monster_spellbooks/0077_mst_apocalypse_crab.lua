-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 612

local categories = require("constants.catalog")

local definition = {
    id = "MST_APOCALYPSE_CRAB",
    slots = {
        -- Source line: 614
        {
            spell_id = "SPELL_CHAOS_BREATH",
            frequency = 62,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

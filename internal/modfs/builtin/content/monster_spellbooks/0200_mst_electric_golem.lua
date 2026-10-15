-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1536

local categories = require("constants.catalog")

local definition = {
    id = "MST_ELECTRIC_GOLEM",
    slots = {
        -- Source line: 1538
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 44,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1539
        {
            spell_id = "SPELL_BLINK",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

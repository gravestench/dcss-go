-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2198

local categories = require("constants.catalog")

local definition = {
    id = "MST_ANTAEUS",
    slots = {
        -- Source line: 2200
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 24,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2201
        {
            spell_id = "SPELL_FLASH_FREEZE",
            frequency = 48,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

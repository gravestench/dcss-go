-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 490

local categories = require("constants.catalog")

local definition = {
    id = "MST_SERVANT_OF_WHISPERS",
    slots = {
        -- Source line: 492
        {
            spell_id = "SPELL_STILL_WINDS",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 493
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 40,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

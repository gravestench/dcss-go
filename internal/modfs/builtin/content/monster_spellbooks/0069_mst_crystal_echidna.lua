-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 560

local categories = require("constants.catalog")

local definition = {
    id = "MST_CRYSTAL_ECHIDNA",
    slots = {
        -- Source line: 562
        {
            spell_id = "SPELL_CRYSTAL_BOLT",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 563
        {
            spell_id = "SPELL_THROW_BARBS",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1386

local categories = require("constants.catalog")

local definition = {
    id = "MST_NEQOXEC",
    slots = {
        -- Source line: 1388
        {
            spell_id = "SPELL_MALMUTATE",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1389
        {
            spell_id = "SPELL_BRAIN_FEED",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

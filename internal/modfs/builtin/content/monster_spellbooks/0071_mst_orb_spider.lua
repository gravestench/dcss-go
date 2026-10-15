-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 575

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORB_SPIDER",
    slots = {
        -- Source line: 577
        {
            spell_id = "SPELL_IOOD",
            frequency = 80,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

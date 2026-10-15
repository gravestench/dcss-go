-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 722

local categories = require("constants.catalog")

local definition = {
    id = "MST_DAEVA",
    slots = {
        -- Source line: 724
        {
            spell_id = "SPELL_SMITING",
            frequency = 64,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

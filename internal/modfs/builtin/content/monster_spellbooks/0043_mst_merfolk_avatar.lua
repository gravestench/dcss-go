-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 348

local categories = require("constants.catalog")

local definition = {
    id = "MST_MERFOLK_AVATAR",
    slots = {
        -- Source line: 350
        {
            spell_id = "SPELL_AVATAR_SONG",
            frequency = 160,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

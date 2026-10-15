-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1352

local categories = require("constants.catalog")

local definition = {
    id = "MST_WHITE_IMP",
    slots = {
        -- Source line: 1354
        {
            spell_id = "SPELL_THROW_FROST",
            frequency = 52,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

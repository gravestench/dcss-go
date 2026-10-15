-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 476

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRONBOUND_FROSTHEART",
    slots = {
        -- Source line: 478
        {
            spell_id = "SPELL_CREEPING_FROST",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

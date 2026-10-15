-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2152

local categories = require("constants.catalog")

local definition = {
    id = "MST_MAGGIE",
    slots = {
        -- Source line: 2154
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2155
        {
            spell_id = "SPELL_MESMERISE",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

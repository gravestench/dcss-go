-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2159

local categories = require("constants.catalog")

local definition = {
    id = "MST_MARGERY",
    slots = {
        -- Source line: 2161
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2162
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

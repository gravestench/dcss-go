-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 709

local categories = require("constants.catalog")

local definition = {
    id = "MST_OPHAN",
    slots = {
        -- Source line: 711
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 32,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 712
        {
            spell_id = "SPELL_HOLY_FLAMES",
            frequency = 32,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

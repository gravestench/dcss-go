-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1603

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORB_OF_FIRE",
    slots = {
        -- Source line: 1605
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 32,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1606
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 32,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1607
        {
            spell_id = "SPELL_MALMUTATE",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

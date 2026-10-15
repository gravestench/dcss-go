-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1101

local categories = require("constants.catalog")

local definition = {
    id = "MST_OGRE_MAGE",
    slots = {
        -- Source line: 1103
        {
            spell_id = "SPELL_BOLT_OF_MAGMA",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1104
        {
            spell_id = "SPELL_HASTE_OTHER",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1105
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1106
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

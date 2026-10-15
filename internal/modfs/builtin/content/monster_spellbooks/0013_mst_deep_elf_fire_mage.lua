-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 122

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_FIRE_MAGE",
    slots = {
        -- Source line: 124
        {
            spell_id = "SPELL_STICKY_FLAME_RANGE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 125
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 126
        {
            spell_id = "SPELL_FIRE_ELEMENTALS",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 127
        {
            spell_id = "SPELL_BLINK",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

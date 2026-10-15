-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2067

local categories = require("constants.catalog")

local definition = {
    id = "MST_JOSEPHINA",
    slots = {
        -- Source line: 2069
        {
            spell_id = "SPELL_SERACFALL",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2070
        {
            spell_id = "SPELL_GHOSTLY_FIREBALL",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2071
        {
            spell_id = "SPELL_BIND_SOULS",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2072
        {
            spell_id = "SPELL_FLASH_FREEZE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

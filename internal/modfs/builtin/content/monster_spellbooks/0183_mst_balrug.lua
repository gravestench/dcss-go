-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1408

local categories = require("constants.catalog")

local definition = {
    id = "MST_BALRUG",
    slots = {
        -- Source line: 1410
        {
            spell_id = "SPELL_STICKY_FLAME_RANGE",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1411
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1412
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1413
        {
            spell_id = "SPELL_SMITING",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

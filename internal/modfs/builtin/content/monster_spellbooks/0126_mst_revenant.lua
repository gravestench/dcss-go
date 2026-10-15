-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 970

local categories = require("constants.catalog")

local definition = {
    id = "MST_REVENANT",
    slots = {
        -- Source line: 972
        {
            spell_id = "SPELL_SPECTRAL_CLOUD",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 973
        {
            spell_id = "SPELL_GHOSTLY_FIREBALL",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 974
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 975
        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

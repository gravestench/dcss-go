-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1143

local categories = require("constants.catalog")

local definition = {
    id = "MST_TENGU_CONJURER",
    slots = {
        -- Source line: 1145
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1146
        {
            spell_id = "SPELL_BATTLESPHERE",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1147
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

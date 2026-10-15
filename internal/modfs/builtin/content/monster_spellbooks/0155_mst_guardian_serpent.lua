-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1207

local categories = require("constants.catalog")

local definition = {
    id = "MST_GUARDIAN_SERPENT",
    slots = {
        -- Source line: 1209
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1210
        {
            spell_id = "SPELL_SLOW",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1211
        {
            spell_id = "SPELL_BLINK_ALLIES_ENCIRCLE",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

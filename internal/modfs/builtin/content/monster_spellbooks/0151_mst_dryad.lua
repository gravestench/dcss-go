-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1178

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRYAD",
    slots = {
        -- Source line: 1180
        {
            spell_id = "SPELL_AWAKEN_VINES",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1181
        {
            spell_id = "SPELL_AWAKEN_FOREST",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1182
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

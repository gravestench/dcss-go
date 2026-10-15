-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 278

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPRIGGAN_DRUID",
    slots = {
        -- Source line: 280
        {
            spell_id = "SPELL_STONE_ARROW",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 281
        {
            spell_id = "SPELL_DRUIDS_CALL",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 282
        {
            spell_id = "SPELL_AWAKEN_FOREST",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 283
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

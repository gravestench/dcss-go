-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1963

local categories = require("constants.catalog")

local definition = {
    id = "MST_JORY",
    slots = {
        -- Source line: 1965
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1966
        {
            spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1967
        {
            spell_id = "SPELL_MESMERISE",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1968
        {
            spell_id = "SPELL_BLINK_CLOSE",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

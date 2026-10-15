-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1237

local categories = require("constants.catalog")

local definition = {
    id = "MST_VAMPIRE",
    slots = {
        -- Source line: 1239
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1240
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1241
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

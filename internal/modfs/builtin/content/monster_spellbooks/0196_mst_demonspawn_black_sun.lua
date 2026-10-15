-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1506

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEMONSPAWN_BLACK_SUN",
    slots = {
        -- Source line: 1508
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1509
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1510
        {
            spell_id = "SPELL_BLACK_MARK",
            frequency = 28,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

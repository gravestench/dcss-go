-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 221

local categories = require("constants.catalog")

local definition = {
    id = "MST_BOUDA",
    slots = {
        -- Source line: 223
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 224
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
                "MON_SPELL_EMERGENCY",
            },
        },
        -- Source line: 225
        {
            spell_id = "SPELL_WEAKENING_GAZE",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
                "MON_SPELL_INSTANT",
            },
        },
        -- Source line: 226
        {
            spell_id = "SPELL_HUNTING_CALL",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

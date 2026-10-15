-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 397

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORC_HIGH_PRIEST",
    slots = {
        -- Source line: 399
        {
            spell_id = "SPELL_PAIN",
            frequency = 10,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 400
        {
            spell_id = "SPELL_SMITING",
            frequency = 10,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 401
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 402
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 10,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

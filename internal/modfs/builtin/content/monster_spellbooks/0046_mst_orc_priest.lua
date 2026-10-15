-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 372

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORC_PRIEST",
    slots = {
        -- Source line: 374
        {
            spell_id = "SPELL_CANTRIP",
            frequency = 13,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 375
        {
            spell_id = "SPELL_PAIN",
            frequency = 13,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 376
        {
            spell_id = "SPELL_SMITING",
            frequency = 13,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 377
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 13,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

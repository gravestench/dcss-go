-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1492

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEMONSPAWN_BLOOD_SAINT",
    slots = {
        -- Source line: 1494
        {
            spell_id = "SPELL_LEGENDARY_DESTRUCTION",
            frequency = 40,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1495
        {
            spell_id = "SPELL_CALL_OF_CHAOS",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

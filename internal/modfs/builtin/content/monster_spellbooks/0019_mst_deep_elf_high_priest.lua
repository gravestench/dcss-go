-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 175

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_HIGH_PRIEST",
    slots = {
        -- Source line: 177
        {
            spell_id = "SPELL_AURA_OF_BRILLIANCE",
            frequency = 25,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 178
        {
            spell_id = "SPELL_CALL_DOWN_DAMNATION",
            frequency = 12,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 179
        {
            spell_id = "SPELL_MALIGN_OFFERING",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 180
        {
            spell_id = "SPELL_SMITING",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

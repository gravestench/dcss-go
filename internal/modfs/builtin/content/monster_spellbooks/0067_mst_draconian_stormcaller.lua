-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 541

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRACONIAN_STORMCALLER",
    slots = {
        -- Source line: 543
        {
            spell_id = "SPELL_SMITING",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 544
        {
            spell_id = "SPELL_SUMMON_DRAKES",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 545
        {
            spell_id = "SPELL_UPHEAVAL",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 192

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_DEATH_MAGE",
    slots = {
        -- Source line: 194
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 195
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 196
        {
            spell_id = "SPELL_CALL_LOST_SOUL",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

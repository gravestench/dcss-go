-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1245

local categories = require("constants.catalog")

local definition = {
    id = "MST_VAMPIRE_MAGE",
    slots = {
        -- Source line: 1247
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1248
        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1249
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1250
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

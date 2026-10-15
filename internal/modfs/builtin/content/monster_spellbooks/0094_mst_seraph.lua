-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 728

local categories = require("constants.catalog")

local definition = {
    id = "MST_SERAPH",
    slots = {
        -- Source line: 730
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 731
        {
            spell_id = "SPELL_SUMMON_HOLIES",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 732
        {
            spell_id = "SPELL_INJURY_BOND",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 733
        {
            spell_id = "SPELL_CLEANSING_FLAME",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

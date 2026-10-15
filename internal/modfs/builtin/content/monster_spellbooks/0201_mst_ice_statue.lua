-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1543

local categories = require("constants.catalog")

local definition = {
    id = "MST_ICE_STATUE",
    slots = {
        -- Source line: 1545
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1546
        {
            spell_id = "SPELL_THROW_ICICLE",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1547
        {
            spell_id = "SPELL_FREEZING_CLOUD",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1548
        {
            spell_id = "SPELL_SUMMON_ICE_BEAST",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1552

local categories = require("constants.catalog")

local definition = {
    id = "MST_OBSIDIAN_STATUE",
    slots = {
        -- Source line: 1554
        {
            spell_id = "SPELL_SUMMON_MINOR_DEMON",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1555
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1556
        {
            spell_id = "SPELL_MESMERISE",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

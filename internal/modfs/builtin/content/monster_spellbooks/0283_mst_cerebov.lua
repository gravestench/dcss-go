-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2245

local categories = require("constants.catalog")

local definition = {
    id = "MST_CEREBOV",
    slots = {
        -- Source line: 2247
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2248
        {
            spell_id = "SPELL_FIRE_STORM",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2249
        {
            spell_id = "SPELL_FIRE_SUMMON",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2250
        {
            spell_id = "SPELL_HASTE",
            frequency = 36,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

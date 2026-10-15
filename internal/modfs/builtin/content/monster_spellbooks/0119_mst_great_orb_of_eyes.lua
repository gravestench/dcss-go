-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 909

local categories = require("constants.catalog")

local definition = {
    id = "MST_GREAT_ORB_OF_EYES",
    slots = {
        -- Source line: 911
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 12,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 912
        {
            spell_id = "SPELL_MINDBURST",
            frequency = 12,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 913
        {
            spell_id = "SPELL_DRAIN_MAGIC",
            frequency = 12,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 914
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 12,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1560

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORANGE_CRYSTAL_STATUE",
    slots = {
        -- Source line: 1562
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1563
        {
            spell_id = "SPELL_BRAIN_FEED",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1564
        {
            spell_id = "SPELL_DRAINING_GAZE",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1565
        {
            spell_id = "SPELL_MASS_CONFUSION",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

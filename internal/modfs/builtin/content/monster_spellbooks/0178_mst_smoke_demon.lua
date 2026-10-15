-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1372

local categories = require("constants.catalog")

local definition = {
    id = "MST_SMOKE_DEMON",
    slots = {
        -- Source line: 1374
        {
            spell_id = "SPELL_STICKY_FLAME_RANGE",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1375
        {
            spell_id = "SPELL_STEAM_BALL",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1376
        {
            spell_id = "SPELL_SMITING",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

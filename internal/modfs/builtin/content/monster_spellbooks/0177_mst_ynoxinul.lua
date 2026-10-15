-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1365

local categories = require("constants.catalog")

local definition = {
    id = "MST_YNOXINUL",
    slots = {
        -- Source line: 1367
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 19,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1368
        {
            spell_id = "SPELL_SUMMON_UFETUBUS",
            frequency = 38,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

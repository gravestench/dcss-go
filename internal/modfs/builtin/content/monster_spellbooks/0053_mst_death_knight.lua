-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 434

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEATH_KNIGHT",
    slots = {
        -- Source line: 436
        {
            spell_id = "SPELL_AGONY_RANGE",
            frequency = 15,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 437
        {
            spell_id = "SPELL_INJURY_MIRROR",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

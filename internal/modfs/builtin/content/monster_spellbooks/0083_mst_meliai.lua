-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 653

local categories = require("constants.catalog")

local definition = {
    id = "MST_MELIAI",
    slots = {
        -- Source line: 655
        {
            spell_id = "SPELL_SMITING",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 656
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

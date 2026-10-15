-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1499

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEMONSPAWN_CORRUPTER",
    slots = {
        -- Source line: 1501
        {
            spell_id = "SPELL_PLANEREND",
            frequency = 40,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 1502
        {
            spell_id = "SPELL_ENTROPIC_WEAVE",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

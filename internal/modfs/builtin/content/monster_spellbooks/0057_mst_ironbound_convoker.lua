-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 463

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRONBOUND_CONVOKER",
    slots = {
        -- Source line: 465
        {
            spell_id = "SPELL_WORD_OF_RECALL",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 466
        {
            spell_id = "SPELL_MIGHT_OTHER",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

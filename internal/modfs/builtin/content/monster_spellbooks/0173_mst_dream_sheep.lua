-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1338

local categories = require("constants.catalog")

local definition = {
    id = "MST_DREAM_SHEEP",
    slots = {
        -- Source line: 1340
        {
            spell_id = "SPELL_DREAM_DUST",
            frequency = 40,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

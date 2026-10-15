-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 342

local categories = require("constants.catalog")

local definition = {
    id = "MST_WATER_NYMPH",
    slots = {
        -- Source line: 344
        {
            spell_id = "SPELL_WATERSTRIKE",
            frequency = 60,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

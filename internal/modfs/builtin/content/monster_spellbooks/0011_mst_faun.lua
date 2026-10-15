-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 106

local categories = require("constants.catalog")

local definition = {
    id = "MST_FAUN",
    slots = {
        -- Source line: 108
        {
            spell_id = "SPELL_CORONA",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 109
        {
            spell_id = "SPELL_STRIP_WILLPOWER",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

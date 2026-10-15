-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1941

local categories = require("constants.catalog")

local definition = {
    id = "MST_AIZUL",
    slots = {
        -- Source line: 1943
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 32,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1944
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1945
        {
            spell_id = "SPELL_SLEEP",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

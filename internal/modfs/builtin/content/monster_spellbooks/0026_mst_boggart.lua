-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 230

local categories = require("constants.catalog")

local definition = {
    id = "MST_BOGGART",
    slots = {
        -- Source line: 232
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 33,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 233
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 234
        {
            spell_id = "SPELL_BLINK",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

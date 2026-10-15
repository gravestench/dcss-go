-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1163

local categories = require("constants.catalog")

local definition = {
    id = "MST_RAKSHASA",
    slots = {
        -- Source line: 1165
        {
            spell_id = "SPELL_FORCE_LANCE",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1166
        {
            spell_id = "SPELL_PHANTOM_MIRROR",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1167
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

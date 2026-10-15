-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 425

local categories = require("constants.catalog")

local definition = {
    id = "MST_WIZARD",
    slots = {
        -- Source line: 427
        {
            spell_id = "SPELL_FIREBALL",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 428
        {
            spell_id = "SPELL_BANISHMENT",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 429
        {
            spell_id = "SPELL_BLINK",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 430
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

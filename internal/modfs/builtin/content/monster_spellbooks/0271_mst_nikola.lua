-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2144

local categories = require("constants.catalog")

local definition = {
    id = "MST_NIKOLA",
    slots = {
        -- Source line: 2146
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2147
        {
            spell_id = "SPELL_CHAIN_LIGHTNING",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2148
        {
            spell_id = "SPELL_BLINK",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

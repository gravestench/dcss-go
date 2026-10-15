-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2084

local categories = require("constants.catalog")

local definition = {
    id = "MST_LOUISE",
    slots = {
        -- Source line: 2086
        {
            spell_id = "SPELL_STONE_ARROW",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2087
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2088
        {
            spell_id = "SPELL_BANISHMENT",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2089
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

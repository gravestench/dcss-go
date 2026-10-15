-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2017

local categories = require("constants.catalog")

local definition = {
    id = "MST_JESSICA",
    slots = {
        -- Source line: 2019
        {
            spell_id = "SPELL_PAIN",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2020
        {
            spell_id = "SPELL_SLOW",
            frequency = 8,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2021
        {
            spell_id = "SPELL_HASTE",
            frequency = 8,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2022
        {
            spell_id = "SPELL_BLINK",
            frequency = 17,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1825

local categories = require("constants.catalog")

local definition = {
    id = "MST_ARACHNE",
    slots = {
        -- Source line: 1827
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1828
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1829
        {
            spell_id = "SPELL_ENSNARE",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1830
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

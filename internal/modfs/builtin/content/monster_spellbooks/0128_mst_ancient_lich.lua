-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 989

local categories = require("constants.catalog")

local definition = {
    id = "MST_ANCIENT_LICH",
    slots = {
        -- Source line: 991
        {
            spell_id = "SPELL_CORROSIVE_BOLT",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 992
        {
            spell_id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 993
        {
            spell_id = "SPELL_HASTE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 994
        {
            spell_id = "SPELL_PETRIFY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 995
        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1684

local categories = require("constants.catalog")

local definition = {
    id = "MST_NATASHA",
    slots = {
        -- Source line: 1686
        {
            spell_id = "SPELL_MAGIC_DART",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1687
        {
            spell_id = "SPELL_CALL_IMP",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1688
        {
            spell_id = "SPELL_SLOW",
            frequency = 13,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1753

local categories = require("constants.catalog")

local definition = {
    id = "MST_MURRAY",
    slots = {
        -- Source line: 1755
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 1756
        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 1757
        {
            spell_id = "SPELL_BLACK_MARK",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

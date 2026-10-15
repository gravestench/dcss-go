-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 694

local categories = require("constants.catalog")

local definition = {
    id = "MST_CURSE_SKULL",
    slots = {
        -- Source line: 696
        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 48,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 697
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

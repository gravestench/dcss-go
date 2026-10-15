-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1816

local categories = require("constants.catalog")

local definition = {
    id = "MST_SERPENT_OF_HELL_TAR",
    slots = {
        -- Source line: 1818
        {
            spell_id = "SPELL_SERPENT_OF_HELL_TAR_BREATH",
            frequency = 35,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 1820
        {
            spell_id = "SPELL_SUMMON_DRAGON",
            frequency = 35,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1792

local categories = require("constants.catalog")

local definition = {
    id = "MST_SERPENT_OF_HELL_GEH",
    slots = {
        -- Source line: 1794
        {
            spell_id = "SPELL_SERPENT_OF_HELL_GEH_BREATH",
            frequency = 35,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 1796
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

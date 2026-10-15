-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 843

local categories = require("constants.catalog")

local definition = {
    id = "MST_GOLDEN_DRAGON",
    slots = {
        -- Source line: 845
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 847
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
        -- Source line: 849
        {
            spell_id = "SPELL_POISONOUS_CLOUD",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

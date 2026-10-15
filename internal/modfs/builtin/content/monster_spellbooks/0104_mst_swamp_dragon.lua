-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 802

local categories = require("constants.catalog")

local definition = {
    id = "MST_SWAMP_DRAGON",
    slots = {
        -- Source line: 804
        {
            spell_id = "SPELL_POISONOUS_CLOUD",
            frequency = 59,
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

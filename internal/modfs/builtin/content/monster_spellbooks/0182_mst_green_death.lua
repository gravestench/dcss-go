-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1400

local categories = require("constants.catalog")

local definition = {
    id = "MST_GREEN_DEATH",
    slots = {
        -- Source line: 1402
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1403
        {
            spell_id = "SPELL_POISONOUS_CLOUD",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1404
        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

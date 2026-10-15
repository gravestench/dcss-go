-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1298

local categories = require("constants.catalog")

local definition = {
    id = "MST_KRAKEN",
    slots = {
        -- Source line: 1300
        {
            spell_id = "SPELL_CREATE_TENTACLES",
            frequency = 44,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
        -- Source line: 1301
        {
            spell_id = "SPELL_INK_CLOUD",
            frequency = 22,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

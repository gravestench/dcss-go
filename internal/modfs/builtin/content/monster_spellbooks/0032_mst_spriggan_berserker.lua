-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 270

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPRIGGAN_BERSERKER",
    slots = {
        -- Source line: 272
        {
            spell_id = "SPELL_BROTHERS_IN_ARMS",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 273
        {
            spell_id = "SPELL_BERSERKER_RAGE",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
        -- Source line: 274
        {
            spell_id = "SPELL_TROGS_HAND",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

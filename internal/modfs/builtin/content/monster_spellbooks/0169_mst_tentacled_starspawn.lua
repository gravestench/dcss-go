-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1311

local categories = require("constants.catalog")

local definition = {
    id = "MST_TENTACLED_STARSPAWN",
    slots = {
        -- Source line: 1313
        {
            spell_id = "SPELL_CREATE_TENTACLES",
            frequency = 66,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1583

local categories = require("constants.catalog")

local definition = {
    id = "MST_MOLTEN_GARGOYLE",
    slots = {
        -- Source line: 1585
        {
            spell_id = "SPELL_BOLT_OF_MAGMA",
            frequency = 57,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

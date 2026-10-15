-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 759

local categories = require("constants.catalog")

local definition = {
    id = "MST_FROST_GIANT",
    slots = {
        -- Source line: 761
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 66,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

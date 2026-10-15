-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 364

local categories = require("constants.catalog")

local definition = {
    id = "MST_BOG_BODY",
    slots = {
        -- Source line: 366
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 28,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 367
        {
            spell_id = "SPELL_SLOW",
            frequency = 28,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

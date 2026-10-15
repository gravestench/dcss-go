-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 953

local categories = require("constants.catalog")

local definition = {
    id = "MST_JOROGUMO",
    slots = {
        -- Source line: 955
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 956
        {
            spell_id = "SPELL_ENSNARE",
            frequency = 40,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

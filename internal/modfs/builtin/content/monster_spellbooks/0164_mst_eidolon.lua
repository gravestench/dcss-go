-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1277

local categories = require("constants.catalog")

local definition = {
    id = "MST_EIDOLON",
    slots = {
        -- Source line: 1279
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1280
        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

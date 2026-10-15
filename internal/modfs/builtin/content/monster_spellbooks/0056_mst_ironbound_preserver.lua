-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 456

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRONBOUND_PRESERVER",
    slots = {
        -- Source line: 458
        {
            spell_id = "SPELL_INJURY_BOND",
            frequency = 21,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 459
        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 41,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

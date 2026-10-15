-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 416

local categories = require("constants.catalog")

local definition = {
    id = "MST_NECROMANCER",
    slots = {
        -- Source line: 418
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 419
        {
            spell_id = "SPELL_AGONY_RANGE",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 420
        {
            spell_id = "SPELL_BIND_SOULS",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

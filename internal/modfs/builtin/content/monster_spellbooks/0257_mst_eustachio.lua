-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2026

local categories = require("constants.catalog")

local definition = {
    id = "MST_EUSTACHIO",
    slots = {
        -- Source line: 2028
        {
            spell_id = "SPELL_SUMMON_SMALL_MAMMAL",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2029
        {
            spell_id = "SPELL_SUMMON_MINOR_DEMON",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2030
        {
            spell_id = "SPELL_BLINK",
            frequency = 27,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1569

local categories = require("constants.catalog")

local definition = {
    id = "MST_STRANGE_MACHINE",
    slots = {
        -- Source line: 1571
        {
            spell_id = "SPELL_SUMMON_ILLUSION",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1572
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

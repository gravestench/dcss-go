-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 667

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPARK_WASP",
    slots = {
        -- Source line: 669
        {
            spell_id = "SPELL_BLINKBOLT",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_LONG_RANGE",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2265

local categories = require("constants.catalog")

local definition = {
    id = "MST_TEST_SPAWNER",
    slots = {
        -- Source line: 2267
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 100,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2268
        {
            spell_id = "SPELL_PLANEREND",
            frequency = 67,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2269
        {
            spell_id = "SPELL_PHANTOM_MIRROR",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

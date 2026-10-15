-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 854

local categories = require("constants.catalog")

local definition = {
    id = "MST_PEARL_DRAGON",
    slots = {
        -- Source line: 856
        {
            spell_id = "SPELL_HOLY_BREATH",
            frequency = 68,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

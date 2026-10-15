-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1193

local categories = require("constants.catalog")

local definition = {
    id = "MST_WENDIGO",
    slots = {
        -- Source line: 1195
        {
            spell_id = "SPELL_SERACFALL",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1196
        {
            spell_id = "SPELL_STUNNING_BURST",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

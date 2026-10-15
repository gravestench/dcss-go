-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 862

local categories = require("constants.catalog")

local definition = {
    id = "MST_AIR_ELEMENTAL",
    slots = {
        -- Source line: 864
        {
            spell_id = "SPELL_STUNNING_BURST",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

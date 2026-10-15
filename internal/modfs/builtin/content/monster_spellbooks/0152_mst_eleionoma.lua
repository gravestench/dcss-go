-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1186

local categories = require("constants.catalog")

local definition = {
    id = "MST_ELEIONOMA",
    slots = {
        -- Source line: 1188
        {
            spell_id = "SPELL_SPLINTERSPRAY",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1189
        {
            spell_id = "SPELL_WOODWEAL",
            frequency = 150,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

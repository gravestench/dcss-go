-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 302

local categories = require("constants.catalog")

local definition = {
    id = "MST_SWAMP_DRAKE",
    slots = {
        -- Source line: 304
        {
            spell_id = "SPELL_NOXIOUS_CLOUD",
            frequency = 54,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

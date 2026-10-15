-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2184

local categories = require("constants.catalog")

local definition = {
    id = "MST_GERYON",
    slots = {
        -- Source line: 2186
        {
            spell_id = "SPELL_SUMMON_HELL_BEAST",
            frequency = 65,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

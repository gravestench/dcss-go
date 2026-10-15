-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1849

local categories = require("constants.catalog")

local definition = {
    id = "MST_DISSOLUTION",
    slots = {
        -- Source line: 1851
        {
            spell_id = "SPELL_SUMMON_EYEBALLS",
            frequency = 62,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

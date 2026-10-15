-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2008

local categories = require("constants.catalog")

local definition = {
    id = "MST_VV",
    slots = {
        -- Source line: 2010
        {
            spell_id = "SPELL_ERUPTION",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2011
        {
            spell_id = "SPELL_PYROCLASTIC_SURGE",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 2012
        {
            spell_id = "SPELL_CREEPING_FROST",
            frequency = 25,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

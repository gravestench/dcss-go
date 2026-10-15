-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 322

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEATH_DRAKE",
    slots = {
        -- Source line: 324
        {
            spell_id = "SPELL_MIASMA_BREATH",
            frequency = 59,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

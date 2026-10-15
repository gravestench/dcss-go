-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1290

local categories = require("constants.catalog")

local definition = {
    id = "MST_PUTRID_MOUTH",
    slots = {
        -- Source line: 1292
        {
            spell_id = "SPELL_MIASMA_BREATH",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1293
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 20,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

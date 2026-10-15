-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 646

local categories = require("constants.catalog")

local definition = {
    id = "MST_BUNYIP",
    slots = {
        -- Source line: 648
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

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 449

local categories = require("constants.catalog")

local definition = {
    id = "MST_VAULT_SENTINEL",
    slots = {
        -- Source line: 451
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 452
        {
            spell_id = "SPELL_SENTINEL_MARK",
            frequency = 58,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

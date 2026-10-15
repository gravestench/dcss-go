-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 470

local categories = require("constants.catalog")

local definition = {
    id = "MST_VAULT_WARDEN",
    slots = {
        -- Source line: 472
        {
            spell_id = "SPELL_SEAL_DOORS",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

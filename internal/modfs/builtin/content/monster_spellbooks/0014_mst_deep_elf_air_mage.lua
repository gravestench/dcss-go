-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 131

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_AIR_MAGE",
    slots = {
        -- Source line: 133
        {
            spell_id = "SPELL_LIGHTNING_BOLT",
            frequency = 40,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 134
        {
            spell_id = "SPELL_BLINK",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

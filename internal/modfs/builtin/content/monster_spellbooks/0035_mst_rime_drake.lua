-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 296

local categories = require("constants.catalog")

local definition = {
    id = "MST_RIME_DRAKE",
    slots = {
        -- Source line: 298
        {
            spell_id = "SPELL_FLASH_FREEZE",
            frequency = 62,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

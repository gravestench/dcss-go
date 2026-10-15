-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1856

local categories = require("constants.catalog")

local definition = {
    id = "MST_SONJA",
    slots = {
        -- Source line: 1858
        {
            spell_id = "SPELL_BLINK",
            frequency = 28,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

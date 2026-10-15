-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1771

local categories = require("constants.catalog")

local definition = {
    id = "MST_POLYPHEMUS",
    slots = {
        -- Source line: 1773
        {
            spell_id = "SPELL_THROW_ALLY",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

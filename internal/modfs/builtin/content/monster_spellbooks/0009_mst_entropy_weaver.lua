-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 92

local categories = require("constants.catalog")

local definition = {
    id = "MST_ENTROPY_WEAVER",
    slots = {
        -- Source line: 94
        {
            spell_id = "SPELL_ENTROPIC_WEAVE",
            frequency = 25,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

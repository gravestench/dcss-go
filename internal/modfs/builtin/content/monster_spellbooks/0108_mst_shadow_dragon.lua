-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 830

local categories = require("constants.catalog")

local definition = {
    id = "MST_SHADOW_DRAGON",
    slots = {
        -- Source line: 832
        {
            spell_id = "SPELL_BOLT_OF_DRAINING",
            frequency = 67,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 245

local categories = require("constants.catalog")

local definition = {
    id = "MST_HELL_HOUND",
    slots = {
        -- Source line: 247
        {
            spell_id = "SPELL_FIRE_BREATH",
            frequency = 20,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 581

local categories = require("constants.catalog")

local definition = {
    id = "MST_BROODMOTHER",
    slots = {
        -- Source line: 583
        {
            spell_id = "SPELL_SUMMON_SPIDERS",
            frequency = 30,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

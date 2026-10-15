-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1515

local categories = require("constants.catalog")

local definition = {
    id = "MST_USHABTI",
    slots = {
        -- Source line: 1517
        {
            spell_id = "SPELL_DEATH_RATTLE",
            frequency = 36,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 1518
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 56,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
        -- Source line: 1519
        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 44,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

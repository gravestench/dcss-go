-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 961

local categories = require("constants.catalog")

local definition = {
    id = "MST_KOBOLD_DEMONOLOGIST",
    slots = {
        -- Source line: 963
        {
            spell_id = "SPELL_CANTRIP",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 964
        {
            spell_id = "SPELL_SUMMON_MINOR_DEMON",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 965
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 19,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

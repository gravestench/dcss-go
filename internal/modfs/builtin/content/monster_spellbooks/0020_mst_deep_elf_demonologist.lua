-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 184

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEEP_ELF_DEMONOLOGIST",
    slots = {
        -- Source line: 186
        {
            spell_id = "SPELL_SUMMON_DEMON",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 187
        {
            spell_id = "SPELL_SUMMON_GREATER_DEMON",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 188
        {
            spell_id = "SPELL_BANISHMENT",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

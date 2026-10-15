-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 2166

local categories = require("constants.catalog")

local definition = {
    id = "MST_FREDERICK",
    slots = {
        -- Source line: 2168
        {
            spell_id = "SPELL_FORCE_LANCE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2169
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2170
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 2171
        {
            spell_id = "SPELL_SPELLFORGED_SERVITOR",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

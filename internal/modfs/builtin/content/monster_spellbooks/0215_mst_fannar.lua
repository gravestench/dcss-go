-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1656

local categories = require("constants.catalog")

local definition = {
    id = "MST_FANNAR",
    slots = {
        -- Source line: 1658
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1659
        {
            spell_id = "SPELL_OZOCUBUS_REFRIGERATION",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1660
        {
            spell_id = "SPELL_SUMMON_ICE_BEAST",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
        -- Source line: 1661
        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

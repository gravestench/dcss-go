-- MST_ERESHKIGAL groups 6 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_COLD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_ERESHKIGAL",
    -- These 6 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_SUMMON_TZITZIMITL",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_PARALYSE",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_SILENCE",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_MAJOR_HEALING",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

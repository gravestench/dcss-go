-- MST_VASHNIA groups 5 DCSS monster spell slots, beginning with
-- SPELL_SPIT_POISON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_VASHNIA",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },

        {
            spell_id = "SPELL_PORTAL_PROJECTILE",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_BLINK_OTHER",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },

        {
            spell_id = "SPELL_BLINK_ALLIES_AWAY",
            frequency = 22,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_BLINK_AWAY",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

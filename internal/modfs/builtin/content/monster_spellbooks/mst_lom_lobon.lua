-- MST_LOM_LOBON groups 5 DCSS monster spell slots, beginning with
-- SPELL_CONJURE_BALL_LIGHTNING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_LOM_LOBON",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_CONJURE_BALL_LIGHTNING",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_GLACIATE",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_POLAR_VORTEX",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_MAJOR_HEALING",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_BLINK_RANGE",
            frequency = 30,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_BOUDA groups 4 DCSS monster spell slots, beginning with
-- SPELL_HEAL_OTHER.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_BOUDA",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_HEAL_OTHER",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
                "MON_SPELL_EMERGENCY",
            },
        },

        {
            spell_id = "SPELL_WEAKENING_GAZE",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
                "MON_SPELL_INSTANT",
            },
        },

        {
            spell_id = "SPELL_HUNTING_CALL",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_WRETCHED_STAR groups 2 DCSS monster spell slots, beginning with
-- SPELL_FORCE_LANCE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_WRETCHED_STAR",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_FORCE_LANCE",
            frequency = 60,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_CORRUPTING_PULSE",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

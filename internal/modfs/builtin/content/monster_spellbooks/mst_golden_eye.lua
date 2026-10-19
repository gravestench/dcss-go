-- MST_GOLDEN_EYE groups 2 DCSS monster spell slots, beginning with
-- SPELL_CONFUSION_GAZE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_GOLDEN_EYE",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_CONFUSION_GAZE",
            frequency = 100,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_INSTANT",
            },
        },

        {
            spell_id = "SPELL_BLINK",
            frequency = 29,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

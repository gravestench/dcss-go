-- MST_FLOATING_EYE groups 1 DCSS monster spell slots, beginning with
-- SPELL_PARALYSIS_GAZE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_FLOATING_EYE",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_PARALYSIS_GAZE",
            frequency = 80,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_INSTANT",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

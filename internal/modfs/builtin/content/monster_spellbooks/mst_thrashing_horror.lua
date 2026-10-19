-- MST_THRASHING_HORROR groups 1 DCSS monster spell slots, beginning with
-- SPELL_MIGHT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_THRASHING_HORROR",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_MIGHT",
            frequency = 59,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

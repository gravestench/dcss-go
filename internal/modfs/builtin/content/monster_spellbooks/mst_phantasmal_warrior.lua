-- MST_PHANTASMAL_WARRIOR groups 1 DCSS monster spell slots, beginning with
-- SPELL_BLINK_CLOSE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_PHANTASMAL_WARRIOR",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BLINK_CLOSE",
            frequency = 67,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

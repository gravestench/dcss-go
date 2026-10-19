-- MST_ELEIONOMA groups 2 DCSS monster spell slots, beginning with
-- SPELL_SPLINTERSPRAY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_ELEIONOMA",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SPLINTERSPRAY",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_WOODWEAL",
            frequency = 150,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

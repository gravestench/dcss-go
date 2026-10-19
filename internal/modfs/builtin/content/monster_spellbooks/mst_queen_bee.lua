-- MST_QUEEN_BEE groups 2 DCSS monster spell slots, beginning with
-- SPELL_BERSERK_OTHER.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_QUEEN_BEE",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BERSERK_OTHER",
            frequency = 50,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },

        {
            spell_id = "SPELL_BERSERK_OTHER",
            frequency = 75,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

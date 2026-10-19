-- MST_DONALD groups 2 DCSS monster spell slots, beginning with SPELL_MIGHT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_DONALD",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_MIGHT",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_HASTE",
            frequency = 34,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

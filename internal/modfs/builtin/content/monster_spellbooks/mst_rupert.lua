-- MST_RUPERT groups 3 DCSS monster spell slots, beginning with
-- SPELL_PARALYSE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_RUPERT",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_PARALYSE",
            frequency = 16,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },

        {
            spell_id = "SPELL_CONFUSE",
            frequency = 16,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },

        {
            spell_id = "SPELL_BERSERKER_RAGE",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

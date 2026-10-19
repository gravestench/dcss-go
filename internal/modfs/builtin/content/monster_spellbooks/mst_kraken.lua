-- MST_KRAKEN groups 2 DCSS monster spell slots, beginning with
-- SPELL_CREATE_TENTACLES.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_KRAKEN",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_CREATE_TENTACLES",
            frequency = 44,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },

        {
            spell_id = "SPELL_INK_CLOUD",
            frequency = 22,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_XTAHUA groups 2 DCSS monster spell slots, beginning with
-- SPELL_SEARING_BREATH.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_XTAHUA",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SEARING_BREATH",
            frequency = 62,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_PARALYSE",
            frequency = 18,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

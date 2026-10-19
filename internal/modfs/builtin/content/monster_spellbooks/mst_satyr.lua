-- MST_SATYR groups 3 DCSS monster spell slots, beginning with
-- SPELL_BATTLECRY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SATYR",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 25,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },

        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 32,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_SLEEP",
            frequency = 16,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

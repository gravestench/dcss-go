-- MST_ASTERION groups 3 DCSS monster spell slots, beginning with
-- SPELL_MAJOR_DESTRUCTION.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_ASTERION",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_MAJOR_DESTRUCTION",
            frequency = 11,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_GREATER_SERVANT_MAKHLEB",
            frequency = 22,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_HASTE",
            frequency = 32,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

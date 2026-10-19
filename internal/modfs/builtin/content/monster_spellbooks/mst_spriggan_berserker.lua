-- MST_SPRIGGAN_BERSERKER groups 3 DCSS monster spell slots, beginning with
-- SPELL_BROTHERS_IN_ARMS.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPRIGGAN_BERSERKER",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BROTHERS_IN_ARMS",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_BERSERKER_RAGE",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_TROGS_HAND",
            frequency = 21,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

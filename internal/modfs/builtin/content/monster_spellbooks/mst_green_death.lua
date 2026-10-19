-- MST_GREEN_DEATH groups 3 DCSS monster spell slots, beginning with
-- SPELL_POISON_ARROW.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_GREEN_DEATH",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_POISON_ARROW",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_POISONOUS_CLOUD",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_VENOM_BOLT",
            frequency = 21,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

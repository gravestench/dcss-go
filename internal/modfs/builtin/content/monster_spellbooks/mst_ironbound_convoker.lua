-- MST_IRONBOUND_CONVOKER groups 2 DCSS monster spell slots, beginning with
-- SPELL_WORD_OF_RECALL.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRONBOUND_CONVOKER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_WORD_OF_RECALL",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_MIGHT_OTHER",
            frequency = 30,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_DEMONSPAWN_BLOOD_SAINT groups 2 DCSS monster spell slots, beginning
-- with SPELL_LEGENDARY_DESTRUCTION.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEMONSPAWN_BLOOD_SAINT",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_LEGENDARY_DESTRUCTION",
            frequency = 40,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_CALL_OF_CHAOS",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

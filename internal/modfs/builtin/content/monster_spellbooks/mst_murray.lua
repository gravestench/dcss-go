-- MST_MURRAY groups 3 DCSS monster spell slots, beginning with
-- SPELL_SYMBOL_OF_TORMENT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_MURRAY",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 11,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 33,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_BLACK_MARK",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

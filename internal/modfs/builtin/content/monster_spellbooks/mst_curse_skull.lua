-- MST_CURSE_SKULL groups 2 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_UNDEAD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_CURSE_SKULL",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SUMMON_UNDEAD",
            frequency = 48,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_SYMBOL_OF_TORMENT",
            frequency = 16,
            flags = {
                "MON_SPELL_MAGICAL",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

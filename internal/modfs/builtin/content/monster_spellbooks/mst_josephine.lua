-- MST_JOSEPHINE groups 3 DCSS monster spell slots, beginning with
-- SPELL_VAMPIRIC_DRAINING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_JOSEPHINE",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_VAMPIRIC_DRAINING",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_GHOSTLY_FIREBALL",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

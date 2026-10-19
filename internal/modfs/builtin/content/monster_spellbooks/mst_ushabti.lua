-- MST_USHABTI groups 3 DCSS monster spell slots, beginning with
-- SPELL_DEATH_RATTLE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_USHABTI",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_DEATH_RATTLE",
            frequency = 36,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 56,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },

        {
            spell_id = "SPELL_DISPEL_UNDEAD_RANGE",
            frequency = 44,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

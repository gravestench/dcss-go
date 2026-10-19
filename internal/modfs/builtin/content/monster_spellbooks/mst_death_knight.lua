-- MST_DEATH_KNIGHT groups 2 DCSS monster spell slots, beginning with
-- SPELL_AGONY_RANGE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_DEATH_KNIGHT",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_AGONY_RANGE",
            frequency = 15,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_INJURY_MIRROR",
            frequency = 20,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

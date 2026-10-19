-- MST_PEACEKEEPER groups 2 DCSS monster spell slots, beginning with
-- SPELL_THROW_BARBS.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_PEACEKEEPER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_THROW_BARBS",
            frequency = 33,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },

        {
            spell_id = "SPELL_BATTLECRY",
            frequency = 25,
            flags = {
                "MON_SPELL_VOCAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

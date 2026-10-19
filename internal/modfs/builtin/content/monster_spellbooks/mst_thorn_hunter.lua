-- MST_THORN_HUNTER groups 2 DCSS monster spell slots, beginning with
-- SPELL_THORN_VOLLEY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_THORN_HUNTER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_THORN_VOLLEY",
            frequency = 43,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },

        {
            spell_id = "SPELL_WALL_OF_BRAMBLES",
            frequency = 22,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

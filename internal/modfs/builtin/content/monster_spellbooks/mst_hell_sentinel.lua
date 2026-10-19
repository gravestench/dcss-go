-- MST_HELL_SENTINEL groups 2 DCSS monster spell slots, beginning with
-- SPELL_HURL_DAMNATION.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_HELL_SENTINEL",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_HURL_DAMNATION",
            frequency = 28,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 14,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

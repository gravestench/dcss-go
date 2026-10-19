-- MST_DRYAD groups 3 DCSS monster spell slots, beginning with
-- SPELL_AWAKEN_VINES.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_DRYAD",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_AWAKEN_VINES",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_AWAKEN_FOREST",
            frequency = 23,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_SPRIGGAN_DRUID groups 4 DCSS monster spell slots, beginning with
-- SPELL_STONE_ARROW.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPRIGGAN_DRUID",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_STONE_ARROW",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_DRUIDS_CALL",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_AWAKEN_FOREST",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_MINOR_HEALING",
            frequency = 15,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_FANNAR groups 4 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_COLD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_FANNAR",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_OZOCUBUS_REFRIGERATION",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_SUMMON_ICE_BEAST",
            frequency = 20,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_BLINK",
            frequency = 10,
            flags = {
                "MON_SPELL_WIZARD",
                "MON_SPELL_EMERGENCY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

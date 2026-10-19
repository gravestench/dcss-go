-- MST_EUSTACHIO groups 3 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_SMALL_MAMMAL.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_EUSTACHIO",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SUMMON_SMALL_MAMMAL",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_SUMMON_MINOR_DEMON",
            frequency = 14,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_BLINK",
            frequency = 27,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

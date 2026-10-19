-- MST_SPHINX groups 4 DCSS monster spell slots, beginning with SPELL_CONFUSE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPHINX",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_CONFUSE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_SLOW",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_PARALYSE",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_SMITING",
            frequency = 11,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_DREAD_LICH groups 4 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_GREATER_DEMON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_DREAD_LICH",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SUMMON_GREATER_DEMON",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_PARALYSE",
            frequency = 18,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_HASTE",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_INVISIBILITY",
            frequency = 12,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

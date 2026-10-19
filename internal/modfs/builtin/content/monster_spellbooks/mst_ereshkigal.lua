-- MST_ERESHKIGAL groups 6 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_COLD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ERESHKIGAL",
    -- These 6 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_COLD,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_TZITZIMITL,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_PARALYSE,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SILENCE,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MAJOR_HEALING,
            frequency = 11,
            flags = {
                flags.MAGICAL,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

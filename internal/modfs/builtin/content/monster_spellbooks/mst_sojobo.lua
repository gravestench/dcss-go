-- MST_SOJOBO groups 5 DCSS monster spell slots, beginning with
-- SPELL_WIND_BLAST.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SOJOBO",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_WIND_BLAST,
            frequency = 28,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_LIGHTNING_BOLT,
            frequency = 14,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_AIRSTRIKE,
            frequency = 14,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_AIR_ELEMENTALS,
            frequency = 14,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_REPEL_MISSILES,
            frequency = 14,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

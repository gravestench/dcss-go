-- MST_CACODEMON groups 5 DCSS monster spell slots, beginning with
-- SPELL_ENERGY_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_CACODEMON",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_ENERGY_BOLT,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SLOW,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_CONFUSE,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MALMUTATE,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_DIG,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

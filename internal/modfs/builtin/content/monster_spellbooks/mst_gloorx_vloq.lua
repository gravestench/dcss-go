-- MST_GLOORX_VLOQ groups 5 DCSS monster spell slots, beginning with
-- SPELL_POISON_ARROW.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_GLOORX_VLOQ",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_POISON_ARROW,
            frequency = 20,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MIASMA_BREATH,
            frequency = 20,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 20,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_DISPEL_UNDEAD_RANGE,
            frequency = 20,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_EXECUTIONERS,
            frequency = 40,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

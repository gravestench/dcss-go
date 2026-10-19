-- MST_HEADMASTER groups 4 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_MANA_VIPER.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_HEADMASTER",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_MANA_VIPER,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_DIMENSION_ANCHOR,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_CLOSE,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_ENERGY_BOLT,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

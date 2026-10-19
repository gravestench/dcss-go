-- MST_REVENANT groups 4 DCSS monster spell slots, beginning with
-- SPELL_SPECTRAL_CLOUD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_REVENANT",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SPECTRAL_CLOUD,
            frequency = 17,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_GHOSTLY_FIREBALL,
            frequency = 17,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_DISPEL_UNDEAD_RANGE,
            frequency = 17,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_AWAY,
            frequency = 17,
            flags = {
                flags.WIZARD,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

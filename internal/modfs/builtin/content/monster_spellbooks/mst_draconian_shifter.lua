-- MST_DRACONIAN_SHIFTER groups 5 DCSS monster spell slots, beginning with
-- SPELL_DIMENSION_ANCHOR.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DRACONIAN_SHIFTER",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_DIMENSION_ANCHOR,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_OTHER,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_RANGE,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_ALLIES_ENCIRCLE,
            frequency = 15,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_AWAY,
            frequency = 15,
            flags = {
                flags.WIZARD,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

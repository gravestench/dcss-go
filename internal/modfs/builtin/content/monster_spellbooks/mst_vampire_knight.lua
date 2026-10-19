-- MST_VAMPIRE_KNIGHT groups 5 DCSS monster spell slots, beginning with
-- SPELL_BLINK_CLOSE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_VAMPIRE_KNIGHT",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BLINK_CLOSE,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_PARALYSE,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_INVISIBILITY,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_VAMPIRIC_DRAINING,
            frequency = 50,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

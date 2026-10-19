-- MST_ILSUIW groups 5 DCSS monster spell slots, beginning with
-- SPELL_THROW_ICICLE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ILSUIW",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_THROW_ICICLE,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_WATER_ELEMENTALS,
            frequency = 22,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_CALL_TIDE,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_INVISIBILITY,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

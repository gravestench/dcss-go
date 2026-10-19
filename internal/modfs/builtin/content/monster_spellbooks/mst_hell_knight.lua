-- MST_HELL_KNIGHT groups 3 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_FIRE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_HELL_KNIGHT",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_FIRE,
            frequency = 17,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 10,
            flags = {
                flags.PRIEST,
                flags.EMERGENCY,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 26,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

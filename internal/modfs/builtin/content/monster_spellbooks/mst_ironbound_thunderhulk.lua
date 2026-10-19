-- MST_IRONBOUND_THUNDERHULK groups 2 DCSS monster spell slots, beginning with
-- SPELL_CALL_DOWN_LIGHTNING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_IRONBOUND_THUNDERHULK",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_CALL_DOWN_LIGHTNING,
            frequency = 50,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_BLINK_RANGE,
            frequency = 25,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

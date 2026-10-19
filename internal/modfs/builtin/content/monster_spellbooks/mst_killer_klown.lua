-- MST_KILLER_KLOWN groups 2 DCSS monster spell slots, beginning with
-- SPELL_BLINK.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_KILLER_KLOWN",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BLINK,
            frequency = 29,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_THROW_PIE,
            frequency = 24,
            flags = {
                flags.NATURAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_WENDIGO groups 2 DCSS monster spell slots, beginning with
-- SPELL_SERACFALL.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_WENDIGO",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SERACFALL,
            frequency = 50,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_STUNNING_BURST,
            frequency = 30,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

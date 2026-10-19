-- MST_ELEMENTAL_WELLSPRING groups 2 DCSS monster spell slots, beginning with
-- SPELL_PRIMAL_WAVE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ELEMENTAL_WELLSPRING",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_PRIMAL_WAVE,
            frequency = 65,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_WATER_ELEMENTALS,
            frequency = 65,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

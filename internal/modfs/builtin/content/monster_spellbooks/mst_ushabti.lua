-- MST_USHABTI groups 3 DCSS monster spell slots, beginning with
-- SPELL_DEATH_RATTLE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_USHABTI",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_DEATH_RATTLE,
            frequency = 36,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_WARNING_CRY,
            frequency = 56,
            flags = {
                flags.VOCAL,
                flags.BREATH,
            },
        },

        {
            spell_id = spells.SPELL_DISPEL_UNDEAD_RANGE,
            frequency = 44,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

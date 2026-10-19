-- MST_PUTRID_MOUTH groups 2 DCSS monster spell slots, beginning with
-- SPELL_MIASMA_BREATH.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_PUTRID_MOUTH",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_MIASMA_BREATH,
            frequency = 50,
            flags = {
                flags.NATURAL,
                flags.BREATH,
            },
        },

        {
            spell_id = spells.SPELL_WARNING_CRY,
            frequency = 20,
            flags = {
                flags.VOCAL,
                flags.BREATH,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_KRAKEN groups 2 DCSS monster spell slots, beginning with
-- SPELL_CREATE_TENTACLES.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_KRAKEN",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_CREATE_TENTACLES,
            frequency = 44,
            flags = {
                flags.NATURAL,
            },
        },

        {
            spell_id = spells.SPELL_INK_CLOUD,
            frequency = 22,
            flags = {
                flags.NATURAL,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_CLOUD_MAGE groups 2 DCSS monster spell slots, beginning with
-- SPELL_AIRSTRIKE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_CLOUD_MAGE",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_AIRSTRIKE,
            frequency = 25,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_POLAR_VORTEX,
            frequency = 40,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

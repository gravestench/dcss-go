-- MST_SAINT_ROKA groups 2 DCSS monster spell slots, beginning with
-- SPELL_BATTLECRY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SAINT_ROKA",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BATTLECRY,
            frequency = 100,
            flags = {
                flags.VOCAL,
            },
        },

        {
            spell_id = spells.SPELL_SMITING,
            frequency = 64,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

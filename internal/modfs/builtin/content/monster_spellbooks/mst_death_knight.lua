-- MST_DEATH_KNIGHT groups 2 DCSS monster spell slots, beginning with
-- SPELL_AGONY_RANGE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEATH_KNIGHT",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_AGONY_RANGE,
            frequency = 15,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_INJURY_MIRROR,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

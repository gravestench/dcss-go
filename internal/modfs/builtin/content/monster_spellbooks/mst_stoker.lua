-- MST_STOKER groups 2 DCSS monster spell slots, beginning with
-- SPELL_WIND_BLAST.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_STOKER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_WIND_BLAST,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_STOKE_FLAMES,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

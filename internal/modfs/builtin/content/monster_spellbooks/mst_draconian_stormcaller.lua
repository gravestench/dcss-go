-- MST_DRACONIAN_STORMCALLER groups 3 DCSS monster spell slots, beginning with
-- SPELL_SMITING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DRACONIAN_STORMCALLER",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SMITING,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_DRAKES,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_UPHEAVAL,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

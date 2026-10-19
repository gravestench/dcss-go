-- MST_SALAMANDER_TYRANT groups 3 DCSS monster spell slots, beginning with
-- SPELL_ERUPTION.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SALAMANDER_TYRANT",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_ERUPTION,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_PYROCLASTIC_SURGE,
            frequency = 50,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_WEAKENING_GAZE,
            frequency = 50,
            flags = {
                flags.WIZARD,
                flags.INSTANT,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

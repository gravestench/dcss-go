-- MST_ZENATA groups 2 DCSS monster spell slots, beginning with
-- SPELL_RESONANCE_STRIKE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ZENATA",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_RESONANCE_STRIKE,
            frequency = 40,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SHEZAS_DANCE,
            frequency = 30,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

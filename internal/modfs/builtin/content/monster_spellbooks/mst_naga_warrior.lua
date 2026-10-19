-- MST_NAGA_WARRIOR groups 2 DCSS monster spell slots, beginning with
-- SPELL_SPIT_POISON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_NAGA_WARRIOR",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SPIT_POISON,
            frequency = 55,
            flags = {
                flags.NATURAL,
                flags.BREATH,
            },
        },

        {
            spell_id = spells.SPELL_BATTLECRY,
            frequency = 25,
            flags = {
                flags.VOCAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

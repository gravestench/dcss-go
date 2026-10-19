-- MST_GREEN_DEATH groups 3 DCSS monster spell slots, beginning with
-- SPELL_POISON_ARROW.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_GREEN_DEATH",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_POISON_ARROW,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_POISONOUS_CLOUD,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_VENOM_BOLT,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

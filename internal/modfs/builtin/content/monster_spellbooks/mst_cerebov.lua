-- MST_CEREBOV groups 4 DCSS monster spell slots, beginning with
-- SPELL_IRON_SHOT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_CEREBOV",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_FIRE_STORM,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_FIRE_SUMMON,
            frequency = 11,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 36,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

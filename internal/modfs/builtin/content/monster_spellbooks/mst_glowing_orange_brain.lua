-- MST_GLOWING_ORANGE_BRAIN groups 5 DCSS monster spell slots, beginning with
-- SPELL_BRAIN_FEED.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_GLOWING_ORANGE_BRAIN",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BRAIN_FEED,
            frequency = 10,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_CAUSE_FEAR,
            frequency = 10,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SHADOW_CREATURES,
            frequency = 10,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MASS_CONFUSION,
            frequency = 10,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 10,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

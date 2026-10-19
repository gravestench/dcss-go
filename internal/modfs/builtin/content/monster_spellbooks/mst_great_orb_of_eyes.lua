-- MST_GREAT_ORB_OF_EYES groups 4 DCSS monster spell slots, beginning with
-- SPELL_PARALYSE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_GREAT_ORB_OF_EYES",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_PARALYSE,
            frequency = 12,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MINDBURST,
            frequency = 12,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_DRAIN_MAGIC,
            frequency = 12,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_CONFUSE,
            frequency = 12,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

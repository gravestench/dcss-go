-- MST_ORB_OF_FIRE groups 3 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_FIRE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ORB_OF_FIRE",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_FIRE,
            frequency = 32,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_FIREBALL,
            frequency = 32,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MALMUTATE,
            frequency = 16,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

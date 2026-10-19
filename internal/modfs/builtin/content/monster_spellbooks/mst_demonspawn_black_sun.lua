-- MST_DEMONSPAWN_BLACK_SUN groups 3 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_DRAINING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEMONSPAWN_BLACK_SUN",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_DRAINING,
            frequency = 18,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_DISPEL_UNDEAD_RANGE,
            frequency = 18,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_BLACK_MARK,
            frequency = 28,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

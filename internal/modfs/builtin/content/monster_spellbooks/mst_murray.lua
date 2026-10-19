-- MST_MURRAY groups 3 DCSS monster spell slots, beginning with
-- SPELL_SYMBOL_OF_TORMENT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MURRAY",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 11,
            flags = {
                flags.MAGICAL,
                flags.NOISY,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_UNDEAD,
            frequency = 33,
            flags = {
                flags.MAGICAL,
                flags.NOISY,
            },
        },

        {
            spell_id = spells.SPELL_BLACK_MARK,
            frequency = 22,
            flags = {
                flags.MAGICAL,
                flags.NOISY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

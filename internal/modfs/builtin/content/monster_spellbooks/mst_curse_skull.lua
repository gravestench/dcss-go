-- MST_CURSE_SKULL groups 2 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_UNDEAD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_CURSE_SKULL",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_UNDEAD,
            frequency = 48,
            flags = {
                flags.MAGICAL,
                flags.NOISY,
            },
        },

        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 16,
            flags = {
                flags.MAGICAL,
                flags.NOISY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

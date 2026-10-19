-- MST_MUMMY_PRIEST groups 4 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_DEMON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MUMMY_PRIEST",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_DEMON,
            frequency = 12,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_UNDEAD,
            frequency = 24,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SMITING,
            frequency = 12,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 12,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

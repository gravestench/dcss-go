-- MST_ORC_HIGH_PRIEST groups 4 DCSS monster spell slots, beginning with
-- SPELL_PAIN.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ORC_HIGH_PRIEST",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_PAIN,
            frequency = 10,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SMITING,
            frequency = 10,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_DEMON,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_HEAL_OTHER,
            frequency = 10,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

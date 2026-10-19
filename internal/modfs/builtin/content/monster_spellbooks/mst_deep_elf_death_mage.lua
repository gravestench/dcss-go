-- MST_DEEP_ELF_DEATH_MAGE groups 3 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_DRAINING.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEEP_ELF_DEATH_MAGE",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_DRAINING,
            frequency = 22,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_VAMPIRIC_DRAINING,
            frequency = 22,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_CALL_LOST_SOUL,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

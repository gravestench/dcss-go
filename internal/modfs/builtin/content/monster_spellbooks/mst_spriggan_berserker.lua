-- MST_SPRIGGAN_BERSERKER groups 3 DCSS monster spell slots, beginning with
-- SPELL_BROTHERS_IN_ARMS.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SPRIGGAN_BERSERKER",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BROTHERS_IN_ARMS,
            frequency = 21,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_BERSERKER_RAGE,
            frequency = 21,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_TROGS_HAND,
            frequency = 21,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

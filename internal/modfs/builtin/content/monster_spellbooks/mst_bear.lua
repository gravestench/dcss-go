-- MST_BEAR groups 1 DCSS monster spell slots, beginning with
-- SPELL_BERSERKER_RAGE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_BEAR",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BERSERKER_RAGE,
            frequency = 100,
            flags = {
                flags.NATURAL,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

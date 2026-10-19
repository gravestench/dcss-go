-- MST_IRON_ELEMENTAL groups 3 DCSS monster spell slots, beginning with
-- SPELL_IRON_SHOT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_IRON_ELEMENTAL",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_METAL_SPLINTERS,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SLOW,
            frequency = 21,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

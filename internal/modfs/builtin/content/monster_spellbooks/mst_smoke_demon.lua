-- MST_SMOKE_DEMON groups 3 DCSS monster spell slots, beginning with
-- SPELL_STICKY_FLAME_RANGE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SMOKE_DEMON",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_STICKY_FLAME_RANGE,
            frequency = 19,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_STEAM_BALL,
            frequency = 19,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SMITING,
            frequency = 19,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

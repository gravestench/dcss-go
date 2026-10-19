-- MST_MNOLEG groups 5 DCSS monster spell slots, beginning with
-- SPELL_MALIGN_GATEWAY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MNOLEG",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_MALIGN_GATEWAY,
            frequency = 27,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_EYEBALLS,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_HORRIBLE_THINGS,
            frequency = 27,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_CALL_OF_CHAOS,
            frequency = 27,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_DIG,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

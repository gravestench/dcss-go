-- MST_FANNAR groups 4 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_COLD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_FANNAR",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_COLD,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_OZOCUBUS_REFRIGERATION,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_ICE_BEAST,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 10,
            flags = {
                flags.WIZARD,
                flags.EMERGENCY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

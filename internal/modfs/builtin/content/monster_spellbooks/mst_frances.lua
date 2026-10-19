-- MST_FRANCES groups 4 DCSS monster spell slots, beginning with
-- SPELL_THROW_ICICLE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_FRANCES",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_THROW_ICICLE,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_DEMON,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

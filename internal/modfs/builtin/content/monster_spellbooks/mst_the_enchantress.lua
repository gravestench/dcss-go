-- MST_THE_ENCHANTRESS groups 6 DCSS monster spell slots, beginning with
-- SPELL_SLOW.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_THE_ENCHANTRESS",
    -- These 6 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SLOW,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_DIMENSION_ANCHOR,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_MASS_CONFUSION,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_STRIP_WILLPOWER,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_REPEL_MISSILES,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

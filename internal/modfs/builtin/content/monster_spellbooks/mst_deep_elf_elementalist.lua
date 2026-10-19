-- MST_DEEP_ELF_ELEMENTALIST groups 5 DCSS monster spell slots, beginning with
-- SPELL_FREEZING_CLOUD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEEP_ELF_ELEMENTALIST",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_FREEZING_CLOUD,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_FIREBALL,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_AWAKEN_EARTH,
            frequency = 44,
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

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

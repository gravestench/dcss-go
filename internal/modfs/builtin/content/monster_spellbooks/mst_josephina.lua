-- MST_JOSEPHINA groups 4 DCSS monster spell slots, beginning with
-- SPELL_SERACFALL.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_JOSEPHINA",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SERACFALL,
            frequency = 36,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_GHOSTLY_FIREBALL,
            frequency = 24,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BIND_SOULS,
            frequency = 24,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_FLASH_FREEZE,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

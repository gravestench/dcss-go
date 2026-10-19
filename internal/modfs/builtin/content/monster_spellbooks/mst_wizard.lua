-- MST_WIZARD groups 4 DCSS monster spell slots, beginning with
-- SPELL_FIREBALL.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_WIZARD",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_FIREBALL,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BANISHMENT,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 12,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_INVISIBILITY,
            frequency = 14,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

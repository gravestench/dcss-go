-- MST_MENKAURE groups 3 DCSS monster spell slots, beginning with SPELL_PAIN.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MENKAURE",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_PAIN,
            frequency = 18,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 18,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SYMBOL_OF_TORMENT,
            frequency = 18,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_CRYSTAL_ECHIDNA groups 2 DCSS monster spell slots, beginning with
-- SPELL_CRYSTAL_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_CRYSTAL_ECHIDNA",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_CRYSTAL_BOLT,
            frequency = 33,
            flags = {
                flags.NATURAL,
            },
        },

        {
            spell_id = spells.SPELL_THROW_BARBS,
            frequency = 33,
            flags = {
                flags.NATURAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

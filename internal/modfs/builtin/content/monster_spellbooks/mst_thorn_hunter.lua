-- MST_THORN_HUNTER groups 2 DCSS monster spell slots, beginning with
-- SPELL_THORN_VOLLEY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_THORN_HUNTER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_THORN_VOLLEY,
            frequency = 43,
            flags = {
                flags.NATURAL,
            },
        },

        {
            spell_id = spells.SPELL_WALL_OF_BRAMBLES,
            frequency = 22,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_DEMONSPAWN_CORRUPTER groups 2 DCSS monster spell slots, beginning with
-- SPELL_PLANEREND.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEMONSPAWN_CORRUPTER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_PLANEREND,
            frequency = 40,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_ENTROPIC_WEAVE,
            frequency = 20,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

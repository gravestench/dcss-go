-- MST_JORGRUN groups 5 DCSS monster spell slots, beginning with SPELL_LRD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_JORGRUN",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_LRD,
            frequency = 16,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_GRASPING_ROOTS,
            frequency = 16,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 16,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_PETRIFY,
            frequency = 16,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_DIG,
            frequency = 16,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

-- MST_HALAZID_WARLOCK groups 4 DCSS monster spell slots, beginning with
-- SPELL_GHOSTLY_SACRIFICE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_HALAZID_WARLOCK",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_GHOSTLY_SACRIFICE,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BOLT_OF_DRAINING,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BOLT_OF_COLD,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SHADOW_CREATURES,
            frequency = 20,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

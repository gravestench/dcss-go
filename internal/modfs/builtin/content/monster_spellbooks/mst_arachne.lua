-- MST_ARACHNE groups 4 DCSS monster spell slots, beginning with
-- SPELL_VENOM_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ARACHNE",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_VENOM_BOLT,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_POISON_ARROW,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_ENSNARE,
            frequency = 34,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BLINK,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

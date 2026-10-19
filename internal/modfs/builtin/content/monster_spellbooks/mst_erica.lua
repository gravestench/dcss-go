-- MST_ERICA groups 5 DCSS monster spell slots, beginning with
-- SPELL_VENOM_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ERICA",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_VENOM_BOLT,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_FORCE_LANCE,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_CONFUSE,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_SLOW,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_INVISIBILITY,
            frequency = 10,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

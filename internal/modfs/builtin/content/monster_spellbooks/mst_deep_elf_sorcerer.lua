-- MST_DEEP_ELF_SORCERER groups 4 DCSS monster spell slots, beginning with
-- SPELL_CORROSIVE_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DEEP_ELF_SORCERER",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_CORROSIVE_BOLT,
            frequency = 18,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BANISHMENT,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 22,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HURL_DAMNATION,
            frequency = 11,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

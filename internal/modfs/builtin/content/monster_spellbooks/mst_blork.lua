-- MST_BLORK groups 5 DCSS monster spell slots, beginning with SPELL_CANTRIP.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_BLORK",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_CANTRIP,
            frequency = 9,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_MAGIC_DART,
            frequency = 9,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_THROW_FROST,
            frequency = 9,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_THROW_FLAME,
            frequency = 9,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HASTE,
            frequency = 9,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

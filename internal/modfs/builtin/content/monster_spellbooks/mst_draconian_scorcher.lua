-- MST_DRACONIAN_SCORCHER groups 5 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_FIRE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DRACONIAN_SCORCHER",
    -- These 5 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_BOLT_OF_FIRE,
            frequency = 13,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_BOLT_OF_MAGMA,
            frequency = 13,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_FIREBALL,
            frequency = 13,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_HURL_DAMNATION,
            frequency = 13,
            flags = {
                flags.WIZARD,
            },
        },

        {
            spell_id = spells.SPELL_CALL_DOWN_DAMNATION,
            frequency = 13,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

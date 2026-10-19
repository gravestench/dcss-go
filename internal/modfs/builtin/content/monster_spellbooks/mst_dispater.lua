-- MST_DISPATER groups 4 DCSS monster spell slots, beginning with
-- SPELL_IRON_SHOT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_DISPATER",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_HURL_DAMNATION,
            frequency = 13,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_HELL_SENTINEL,
            frequency = 26,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

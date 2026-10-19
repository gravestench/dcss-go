-- MST_OBSIDIAN_STATUE groups 3 DCSS monster spell slots, beginning with
-- SPELL_SUMMON_MINOR_DEMON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_OBSIDIAN_STATUE",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_MINOR_DEMON,
            frequency = 33,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_SUMMON_DEMON,
            frequency = 33,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_MESMERISE,
            frequency = 33,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

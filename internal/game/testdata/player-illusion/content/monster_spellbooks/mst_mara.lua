-- Force the source Mara illusion slot in the live integration fixture.
-- The test still uses the ordinary book, planner, scheduler, and resolver.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MARA",
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_ILLUSION,
            frequency = 200,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

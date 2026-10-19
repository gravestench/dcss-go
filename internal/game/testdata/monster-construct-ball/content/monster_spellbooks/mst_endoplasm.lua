-- This live-game fixture offers only Conjure Ball Lightning, so the cast
-- crosses the ordinary spellbook selection and summon resolution path.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_CONJURE_BALL_LIGHTNING,
            frequency = 200,
            flags = { flags.MAGICAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

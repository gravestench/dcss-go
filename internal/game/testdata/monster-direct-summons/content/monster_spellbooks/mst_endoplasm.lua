-- Keep the normal Endoplasm profile but give it one source summon spell.
-- The effect is found by path; this overlay does not edit a Go registry.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
            frequency = 200,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

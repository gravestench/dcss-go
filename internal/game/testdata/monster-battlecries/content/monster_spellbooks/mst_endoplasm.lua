-- A sparse source-shaped vocal slot gives a common Dungeon caster a
-- same-genus ally cry without adding a Go spell dispatcher.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_BATTLECRY,
            frequency = 200,
            flags = {
                flags.VOCAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

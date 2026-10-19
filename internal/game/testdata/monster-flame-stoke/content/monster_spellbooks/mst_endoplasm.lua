-- A sparse test overlay gives the ordinary live caster only Stoke Flames.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_STOKE_FLAMES,
            frequency = 200,
            flags = { flags.WIZARD },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

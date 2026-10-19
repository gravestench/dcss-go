-- A sparse test overlay gives the ordinary live caster only Holy Flames.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_HOLY_FLAMES,
            frequency = 200,
            flags = { flags.MAGICAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

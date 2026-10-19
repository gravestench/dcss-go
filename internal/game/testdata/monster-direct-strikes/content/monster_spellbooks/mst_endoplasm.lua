-- This sparse integration overlay gives a common D:1 caster a direct
-- Smiting spell so a real action tests the Lua target and damage path.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_SMITING,
            frequency = 200,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

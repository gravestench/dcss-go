-- This sparse book overlay exercises Major Healing through the live AI.
-- The healing effect remains the base mod's production Lua file.
local categories = require("constants.catalog")
local spells = require("ids.spells")
local flags = require("constants.monster_spell_flags")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_MAJOR_HEALING,
            frequency = 200,
            flags = { flags.WIZARD },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

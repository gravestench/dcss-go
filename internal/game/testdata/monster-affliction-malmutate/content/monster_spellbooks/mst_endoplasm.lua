-- Put one source spell into an early monster's book so the live Dungeon
-- action loop can exercise its ordinary Lua spell-selection path.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_MALMUTATE,
            frequency = 200,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

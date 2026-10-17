-- Integration fixture: a reflectable second-slot monster projectile.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 9,
            flags = { flags.NATURAL },
        },
        {
            spell_id = spells.SPELL_STONE_ARROW,
            frequency = 18,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

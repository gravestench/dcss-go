-- Give the source Endoplasm only its natural Freeze spell so this overlay
-- exercises the real effect on a monster foe during an ordinary turn.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 200,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

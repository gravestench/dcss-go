-- The zero-weight Iron Shot slot is eligible for the servitor's copied
-- spell list. The live caster itself chooses only the Servitor spell.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_IRON_SHOT,
            frequency = 0,
            flags = { flags.WIZARD },
        },

        {
            spell_id = spells.SPELL_SPELLFORGED_SERVITOR,
            frequency = 200,
            flags = { flags.WIZARD },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

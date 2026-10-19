-- Exercise the real Flay spell on a natural Human through monster AI.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FLAY,
            frequency = 200,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

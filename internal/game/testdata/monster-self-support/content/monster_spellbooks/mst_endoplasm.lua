-- Exercise the real monster turn path with one self-support spell. The
-- overlay changes only this book; Haste itself comes from the base mod.
local categories = require("constants.catalog")
local spells = require("ids.spells")
local flags = require("constants.monster_spell_flags")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_HASTE,
            frequency = 200,
            flags = { flags.WIZARD },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

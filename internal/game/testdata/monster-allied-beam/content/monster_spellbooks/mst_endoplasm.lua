-- Give an ordinary D:1 monster a beam slot so a real allied action proves
-- that the selected enemy actor reaches shared beam planning and contact.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_MAGIC_DART,
            frequency = 200,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

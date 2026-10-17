-- Test mod: two implemented effects in one source-shaped monster book.
local categories = require("constants.catalog")
local spells = require("ids.spells")
local flags = require("constants.monster_spell_flags")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 9,
            flags = { flags.NATURAL },
        },

        {
            spell_id = spells.SPELL_SLUG_DART,
            frequency = 18,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

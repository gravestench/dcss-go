-- A live save test forces Mara's fake-copy slot while retaining the same
-- production spell, actor, and summon code used by the ordinary book.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MARA",
    slots = {
        {
            spell_id = spells.SPELL_FAKE_MARA_SUMMON,
            frequency = 200,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

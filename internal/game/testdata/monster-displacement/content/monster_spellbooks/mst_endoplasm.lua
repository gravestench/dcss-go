local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

-- A sparse test overlay grants one ordinary monster Blink. The normal
-- spellbook selector and effect discovery must find the bundled Lua rule.
local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_BLINK,
            frequency = 200,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

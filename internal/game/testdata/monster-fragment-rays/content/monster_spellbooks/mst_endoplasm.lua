-- Give a live generated caster one fragment ray so the integration test
-- exercises real spell choice, triple-armour contact, and save continuation.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_METAL_SPLINTERS,
            frequency = 200,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

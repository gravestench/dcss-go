-- Force the real monster AI through Wind Blast on a generated Dungeon floor.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_WIND_BLAST,
            frequency = 200,
            flags = {
                flags.NATURAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

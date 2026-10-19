-- A sparse test mod gives one real Dungeon caster a targeted hex in slot two.
-- The source book still supplies Freeze as slot one.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 9,
            flags = {
                flags.NATURAL,
            },
        },

        {
            spell_id = spells.SPELL_SAP_MAGIC,
            frequency = 18,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

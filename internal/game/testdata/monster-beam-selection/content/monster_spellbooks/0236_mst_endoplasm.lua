-- Integration mod: two source-shaped slots, with Magic Dart supplied by
-- a sparse override at its normal relative effect path.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FREEZE,
            frequency = 9,
            flags = { flags.NATURAL },
        },
        {
            spell_id = spells.SPELL_MAGIC_DART,
            frequency = 18,
            flags = { flags.NATURAL },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

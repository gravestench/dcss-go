-- Force a source Weakening Gaze through the real monster decision and
-- cast scheduler without changing the bundled Endoplasm spellbook.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_WEAKENING_GAZE,
            frequency = 200,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

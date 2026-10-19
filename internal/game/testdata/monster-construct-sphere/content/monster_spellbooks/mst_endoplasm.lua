-- The seeded first prospect chooses Battlesphere. Once one exists, the
-- eligible Stone Arrow slot lets later AI casts trigger its saved sphere.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_BATTLESPHERE,
            frequency = 100,
            flags = { flags.WIZARD },
        },

        {
            spell_id = spells.SPELL_STONE_ARROW,
            frequency = 100,
            flags = { flags.WIZARD },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

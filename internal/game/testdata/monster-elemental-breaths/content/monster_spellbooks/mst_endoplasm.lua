-- Give a live Dungeon caster one natural breath slot so the integration test
-- exercises the production decision, intent, ray, and save path together.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_FIRE_BREATH,
            frequency = 200,
            flags = {
                flags.NATURAL,
                flags.BREATH,
                flags.NOISY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

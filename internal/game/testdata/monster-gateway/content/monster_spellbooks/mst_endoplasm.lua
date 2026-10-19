-- This test overlays only the Endoplasm book. The production Malign Gateway
-- policy, actor components, grid, and save code remain exactly as shipped.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_ENDOPLASM",
    slots = {
        {
            spell_id = spells.SPELL_MALIGN_GATEWAY,
            frequency = 200,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition

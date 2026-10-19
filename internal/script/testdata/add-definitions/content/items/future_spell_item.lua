-- The item refers to a spell added in the same overlay, testing forward catalog resolution.

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "MY_MOD_FUTURE_SPELL_ITEM",
    name = "future spell token",
    class = "OBJ_TEST_RELICS",
    spell_id = spells.SPELL_TEST_SPARK,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

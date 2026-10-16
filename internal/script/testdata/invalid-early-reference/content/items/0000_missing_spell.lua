local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "MY_MOD_BAD_SPELL_ITEM",
    name = "bad spell token",
    class = "OBJ_TEST_RELICS",
    spell_id = spells.SPELL_NOT_REAL,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

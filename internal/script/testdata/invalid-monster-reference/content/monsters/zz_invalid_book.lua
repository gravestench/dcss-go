-- This monster names an unknown spellbook and must fail catalog validation.

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TEST_BAD_BOOK",
    name = "bad book monster",
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = "MST_DOES_NOT_EXIST",
}

register.definition(categories.MONSTERS, definition)

return definition

local categories = require("constants.catalog")

local definition = {
    id = "MY_MOD_TOKEN",
    name = "test token",
    class = "OBJ_TEST_RELICS",
    stackable = true,
}

register.definition(categories.ITEMS, definition)

return definition

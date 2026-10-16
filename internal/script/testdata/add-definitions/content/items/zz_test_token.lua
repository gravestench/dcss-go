local categories = require("constants.catalog")

local definition = {
    id = "MY_MOD_TOKEN",
    name = "test token",
    class = "OBJ_TEST_RELICS",
    stackable = true,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

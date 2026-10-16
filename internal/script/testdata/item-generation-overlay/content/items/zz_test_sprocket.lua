local categories = require("constants.catalog")
local classes = require("ids.object_classes")

local definition = {
    id = "WPN_TEST_SPROCKET",
    name = "test sprocket",
    class = classes.OBJ_WEAPONS,
    stackable = false,
    generation = {
        mode = "random",
        weight = 7,
    },
}

register.definition(categories.ITEMS, definition)

return definition

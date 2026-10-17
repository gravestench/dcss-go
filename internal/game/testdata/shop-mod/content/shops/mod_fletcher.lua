local categories = require("constants.catalog")
local classes = require("ids.object_classes")

local definition = {
    id = "SHOP_MOD_FLETCHER",
    name = "Fletcher's Shop",
    identifies_stock = true,
    generation_weight = 1,
    class_weights = {
        { class = classes.OBJ_MISSILES, weight = 1 },
    },
}

register.definition(categories.SHOPS, definition)

return definition

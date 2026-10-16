local capabilities = require("constants.jewellery_capabilities")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.test_items")
local kinds = require("constants.jewellery_kind")

local definition = {
    id = ids.AMU_REFLECTOR,
    name = "amulet of mirrored moss",
    class = classes.OBJ_JEWELLERY,
    stackable = false,
    jewellery = {
        kind = kinds.AMULET,
        effects = {
            [capabilities.REFLECTION] = 1,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

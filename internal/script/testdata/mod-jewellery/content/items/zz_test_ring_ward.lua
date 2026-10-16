local capabilities = require("constants.jewellery_capabilities")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.test_items")
local jewellery_kinds = require("constants.jewellery_kind")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = ids.RING_WARD,
    name = "ring of warding",
    class = classes.OBJ_JEWELLERY,
    stackable = false,
    jewellery = {
        kind = jewellery_kinds.RING,
        pluses = true,
        effects = {
            [capabilities.EV] = magnitudes.ITEM_PLUS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

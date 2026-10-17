local categories = require("constants.catalog")
local classes = require("constants.item_classes")
local pools = require("constants.appearance_pools")

local definition = {
    id = "MOD_ANCESTRAL_CHARM",
    name = "ancestor's charm",
    glyph = 61,
    class = classes.JEWELLERY,
    class_value = 6,
    subtype_value = 1000,
    stackable = false,
    explicitly_removed = false,
    identification_pool = pools.AMULET,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

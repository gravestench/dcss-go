local categories = require("constants.catalog")

local definition = {
    id = "POT_MISSING_EFFECT",
    name = "potion of missing effect",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 999,
    stackable = true,
    naming = {
        text = "potion of missing effect",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

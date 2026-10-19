-- A scroll of renewal enters the item catalog before effect registration is tested separately.

local categories = require("constants.catalog")

local definition = {
    id = "SCR_MOD_TEST",
    name = "scroll of renewal",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 100,
    stackable = true,
    naming = {
        text = "scroll of renewal",
        kind = "static",
    },
    explicitly_removed = false,
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

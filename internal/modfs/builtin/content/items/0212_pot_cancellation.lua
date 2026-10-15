-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 678

local categories = require("constants.catalog")

local definition = {
    id = "POT_CANCELLATION",
    name = "potion of cancellation",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 12,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:678
    naming = {
        text = "potion of cancellation",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 783

local categories = require("constants.catalog")

local definition = {
    id = "AMU_INACCURACY",
    name = "amulet of inaccuracy",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 42,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:783
    naming = {
        text = "amulet of inaccuracy",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1005

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_TRANSFIGURATIONS",
    name = "book of Transfigurations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 14,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1005
    naming = {
        text = "book of Transfigurations",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

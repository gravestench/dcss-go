-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1061

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_TOUCH",
    name = "book of Touch",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 70,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1061
    naming = {
        text = "book of Touch",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

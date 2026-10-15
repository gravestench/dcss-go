-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1019

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_ANNIHILATIONS",
    name = "book of Annihilations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 40,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1019
    naming = {
        text = "book of Annihilations",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1066

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_RANDART_THEME",
    name = "book of Fixed Theme",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 44,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1066
    naming = {
        text = "book of Fixed Theme",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1156

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_MANUAL",
    name = "manual",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 45,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1156
    naming = {
        text = "manual",
        kind = "manual_skill",
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

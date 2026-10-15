-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1169

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_BUGGY_DESTRUCTION",
    name = "tome of obsoleteness",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 46,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1169
    naming = {
        text = "tome of obsoleteness",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

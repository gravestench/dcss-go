-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1126

local categories = require("constants.catalog")

local definition = {
    id = "ROD_DESTRUCTION",
    name = "removed rod",
    glyph = 124,
    class = "OBJ_RODS",
    class_value = 14,
    subtype_value = 4,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1126
    naming = {
        text = "removed rod",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

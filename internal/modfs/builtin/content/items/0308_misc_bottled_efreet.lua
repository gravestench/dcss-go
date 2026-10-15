-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 968

local categories = require("constants.catalog")

local definition = {
    id = "MISC_BOTTLED_EFREET",
    name = "empty flask",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:968
    naming = {
        text = "empty flask",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

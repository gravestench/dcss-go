-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 978

local categories = require("constants.catalog")

local definition = {
    id = "MISC_ZIGGURAT",
    name = "figurine of a ziggurat",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 23,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:978
    naming = {
        text = "figurine of a ziggurat",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

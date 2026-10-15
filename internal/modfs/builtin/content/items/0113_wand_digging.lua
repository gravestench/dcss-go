-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 631

local categories = require("constants.catalog")

local definition = {
    id = "WAND_DIGGING",
    name = "wand of digging",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 11,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:631
    naming = {
        text = "wand of digging",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

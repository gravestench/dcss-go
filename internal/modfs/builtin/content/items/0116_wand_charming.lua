-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 634

local categories = require("constants.catalog")

local definition = {
    id = "WAND_CHARMING",
    name = "wand of charming",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 16,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:634
    naming = {
        text = "wand of charming",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

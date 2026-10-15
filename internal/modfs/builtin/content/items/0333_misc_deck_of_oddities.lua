-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 950

local categories = require("constants.catalog")

local definition = {
    id = "MISC_DECK_OF_ODDITIES",
    name = "removed deck",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 25,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:950
    naming = {
        text = "removed deck",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

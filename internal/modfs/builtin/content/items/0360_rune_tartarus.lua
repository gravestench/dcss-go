-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 922

local categories = require("constants.catalog")

local definition = {
    id = "RUNE_TARTARUS",
    name = "bone rune of Zot",
    glyph = 125,
    class = "OBJ_RUNES",
    class_value = 15,
    subtype_value = 10,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:922
    naming = {
        text = "bone rune of Zot",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

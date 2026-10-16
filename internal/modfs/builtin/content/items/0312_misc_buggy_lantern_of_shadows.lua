-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 963

local categories = require("constants.catalog")

local definition = {
    id = "MISC_BUGGY_LANTERN_OF_SHADOWS",
    name = "removed lantern of shadows",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 4,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:963
    naming = {
        text = "removed lantern of shadows",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

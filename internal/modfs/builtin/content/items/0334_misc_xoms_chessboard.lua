-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 979

local categories = require("constants.catalog")

local definition = {
    id = "MISC_XOMS_CHESSBOARD",
    name = "piece from Xom's chessboard",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 26,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:979
    naming = {
        text = "piece from Xom's chessboard",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition

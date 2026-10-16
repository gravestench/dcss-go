-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 747

local categories = require("constants.catalog")

local definition = {
    id = "RING_ATTENTION",
    name = "ring of obsoleteness",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 9,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:747
    naming = {
        text = "ring of obsoleteness",
        kind = "static",
    },
    explicitly_removed = true,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

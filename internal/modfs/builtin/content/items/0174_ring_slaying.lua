-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 754

local categories = require("constants.catalog")

local definition = {
    id = "RING_SLAYING",
    name = "ring of slaying",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:754
    naming = {
        text = "ring of slaying",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

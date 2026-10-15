-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 773

local categories = require("constants.catalog")

local definition = {
    id = "RING_TELEPORT_CONTROL",
    name = "ring of teleport control",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 23,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:773
    naming = {
        text = "ring of teleport control",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

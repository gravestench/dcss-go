-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 759

local categories = require("constants.catalog")

local definition = {
    id = "RING_SUSTAIN_ATTRIBUTES",
    name = "ring of sustain attributes",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 12,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:759
    naming = {
        text = "ring of sustain attributes",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

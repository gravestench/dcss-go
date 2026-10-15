-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 756

local categories = require("constants.catalog")

local definition = {
    id = "RING_RESIST_CORROSION",
    name = "ring of resist corrosion",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 8,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:756
    naming = {
        text = "ring of resist corrosion",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

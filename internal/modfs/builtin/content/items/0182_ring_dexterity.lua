-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 762

local categories = require("constants.catalog")

local definition = {
    id = "RING_DEXTERITY",
    name = "ring of dexterity",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 14,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:762
    naming = {
        text = "ring of dexterity",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

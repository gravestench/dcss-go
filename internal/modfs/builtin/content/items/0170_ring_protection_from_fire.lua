-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 750

local categories = require("constants.catalog")

local definition = {
    id = "RING_PROTECTION_FROM_FIRE",
    name = "ring of protection from fire",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 2,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:750
    naming = {
        text = "ring of protection from fire",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

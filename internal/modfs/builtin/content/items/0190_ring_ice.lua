-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 770

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")

local definition = {
    id = "RING_ICE",
    name = "ring of ice",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 22,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.RING,
    },

    -- Source: crawl-ref/source/item-name.cc:770
    naming = {
        text = "ring of ice",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 757

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")

local definition = {
    id = "RING_EVASION",
    name = "ring of evasion",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 11,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/item-prop.cc:2129-2135
        pluses = true,
    },

    -- Source: crawl-ref/source/item-name.cc:757
    naming = {
        text = "ring of evasion",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

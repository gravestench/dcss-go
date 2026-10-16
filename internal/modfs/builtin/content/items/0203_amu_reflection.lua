-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 788

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")

local definition = {
    id = "AMU_REFLECTION",
    name = "amulet of reflection",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 46,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.AMULET,
    },

    -- Source: crawl-ref/source/item-name.cc:788
    naming = {
        text = "amulet of reflection",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

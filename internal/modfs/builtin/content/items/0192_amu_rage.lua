-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 778

local categories = require("constants.catalog")

local definition = {
    id = "AMU_RAGE",
    name = "amulet of rage",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 35,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:778
    naming = {
        text = "amulet of rage",
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

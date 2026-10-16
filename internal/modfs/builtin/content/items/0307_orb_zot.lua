-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1207

local categories = require("constants.catalog")

local definition = {
    id = "ORB_ZOT",
    name = "Orb of Zot",
    glyph = 123,
    class = "OBJ_ORBS",
    class_value = 10,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1207
    naming = {
        text = "Orb of Zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

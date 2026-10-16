-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 962

local categories = require("constants.catalog")

local definition = {
    id = "MISC_LAMP_OF_FIRE",
    name = "removed lamp of fire",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 2,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:962
    naming = {
        text = "removed lamp of fire",
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

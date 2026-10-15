-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 981

local categories = require("constants.catalog")

local definition = {
    id = "MISC_CONDENSER_VANE",
    name = "condenser vane",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 28,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:981
    naming = {
        text = "condenser vane",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 671

local categories = require("constants.catalog")

local definition = {
    id = "POT_CURING",
    name = "potion of curing",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:671
    naming = {
        text = "potion of curing",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

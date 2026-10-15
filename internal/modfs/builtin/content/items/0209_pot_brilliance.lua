-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 676

local categories = require("constants.catalog")

local definition = {
    id = "POT_BRILLIANCE",
    name = "potion of brilliance",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 4,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:676
    naming = {
        text = "potion of brilliance",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

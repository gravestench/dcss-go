-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 713

local categories = require("constants.catalog")

local definition = {
    id = "SCR_FOG",
    name = "scroll of fog",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 15,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:713
    naming = {
        text = "scroll of fog",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition

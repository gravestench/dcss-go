-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 720

local categories = require("constants.catalog")

local definition = {
    id = "SCR_HOLY_WORD",
    name = "scroll of holy word",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 21,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:720
    naming = {
        text = "scroll of holy word",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition

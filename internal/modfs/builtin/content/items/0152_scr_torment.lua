-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 707

local categories = require("constants.catalog")

local definition = {
    id = "SCR_TORMENT",
    name = "scroll of torment",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 8,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:707
    naming = {
        text = "scroll of torment",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        rarity = "RARITY_RARE",
        weight = 15,
    },
}

register.definition(categories.ITEMS, definition)

return definition

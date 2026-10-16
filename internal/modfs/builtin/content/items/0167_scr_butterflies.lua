-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 710

local categories = require("constants.catalog")

local definition = {
    id = "SCR_BUTTERFLIES",
    name = "scroll of butterflies",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 27,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:710
    naming = {
        text = "scroll of butterflies",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        rarity = "RARITY_UNCOMMON",
        weight = 36,
    },
}

register.definition(categories.ITEMS, definition)

return definition

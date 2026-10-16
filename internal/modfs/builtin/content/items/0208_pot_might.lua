-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 674

local categories = require("constants.catalog")

local definition = {
    id = "POT_MIGHT",
    name = "potion of might",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 3,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:674
    naming = {
        text = "potion of might",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        rarity = "RARITY_UNCOMMON",
        weight = 67,
    },
}

register.definition(categories.ITEMS, definition)

return definition

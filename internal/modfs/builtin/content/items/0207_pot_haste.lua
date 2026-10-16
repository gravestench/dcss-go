-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 673

local categories = require("constants.catalog")

local definition = {
    id = "POT_HASTE",
    name = "potion of haste",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 2,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:673
    naming = {
        text = "potion of haste",
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

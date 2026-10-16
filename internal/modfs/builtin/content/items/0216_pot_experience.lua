-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 682

local categories = require("constants.catalog")

local definition = {
    id = "POT_EXPERIENCE",
    name = "potion of experience",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 19,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:682
    naming = {
        text = "potion of experience",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        rarity = "RARITY_VERY_RARE",
        weight = 2,
    },
}

register.definition(categories.ITEMS, definition)

return definition

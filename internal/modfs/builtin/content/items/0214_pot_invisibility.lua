-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 680

local categories = require("constants.catalog")

local definition = {
    id = "POT_INVISIBILITY",
    name = "potion of invisibility",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 14,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:680
    naming = {
        text = "potion of invisibility",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    generation = {
        mode = "random",
        rarity = "RARITY_RARE",
        weight = 35,
    },
}

register.definition(categories.ITEMS, definition)

return definition

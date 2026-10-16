-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1700
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 696

local categories = require("constants.catalog")

local definition = {
    id = "FOOD_RATION",
    name = "removed food",
    property_name = "buggy ration",
    glyph = 37,
    class = "OBJ_FOOD",
    class_value = 4,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:1700
    naming = {
        text = "removed food",
        kind = "static",
    },
    explicitly_removed = true,
    food = {
        normal_nutrition = 3400,
        carnivore_nutrition = 1900,
        herbivore_nutrition = 1900,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

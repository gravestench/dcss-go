-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1700
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 698

local categories = require("constants.catalog")

local definition = {
    id = "FOOD_UNUSED",
    name = "removed food",
    property_name = "buggy pizza",
    glyph = 37,
    class = "OBJ_FOOD",
    class_value = 4,
    subtype_value = 6,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:1700
    naming = {
        text = "removed food",
        kind = "static",
    },
    explicitly_removed = true,
    food = {
        normal_nutrition = 0,
        carnivore_nutrition = 0,
        herbivore_nutrition = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition

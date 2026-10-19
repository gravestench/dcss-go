-- removed food (FOOD_CHUNK) belongs to OBJ_FOOD.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "FOOD_CHUNK",
    name = "removed food",
    property_name = "buggy chunk",
    glyph = 37,
    class = "OBJ_FOOD",
    class_value = 4,
    subtype_value = 21,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- removed food has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "removed food",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    food = {
        normal_nutrition = 1000,
        carnivore_nutrition = 1300,
        herbivore_nutrition = 0,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether removed food enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

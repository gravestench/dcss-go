-- removed food (FOOD_PIZZA) belongs to OBJ_FOOD.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "FOOD_PIZZA",
    name = "removed food",
    property_name = "buggy fruit",
    glyph = 37,
    class = "OBJ_FOOD",
    class_value = 4,
    subtype_value = 8,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- removed food has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "removed food",
        kind = "static",
    },
    explicitly_removed = false,
    food = {
        normal_nutrition = 1500,
        carnivore_nutrition = 0,
        herbivore_nutrition = 0,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- The "removed" name is legacy catalog text, not the removed flag.
    -- None mode retains the ID without creating new copies through generation.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

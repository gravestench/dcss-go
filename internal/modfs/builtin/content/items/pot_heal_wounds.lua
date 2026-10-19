-- potion of heal wounds (POT_HEAL_WOUNDS) belongs to OBJ_POTIONS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "POT_HEAL_WOUNDS",
    name = "potion of heal wounds",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 1,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- potion of heal wounds has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "potion of heal wounds",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether potion of heal wounds enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_COMMON",
        weight = 105,
    },
}

register.definition(categories.ITEMS, definition)

return definition

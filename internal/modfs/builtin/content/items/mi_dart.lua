-- dart (MI_DART) belongs to OBJ_MISSILES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "MI_DART",
    name = "dart",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc
    -- dart has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "dart",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 0,
        mulch_rate = 12,
        price = 2,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether dart enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition

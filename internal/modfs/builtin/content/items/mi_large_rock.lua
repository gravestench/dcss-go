-- large rock (MI_LARGE_ROCK) belongs to OBJ_MISSILES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "MI_LARGE_ROCK",
    name = "large rock",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 6,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc
    -- large rock has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "large rock",
        kind = "static",
    },
    explicitly_removed = false,
    missile = {
        damage = 20,
        mulch_rate = 25,
        price = 7,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether large rock enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition

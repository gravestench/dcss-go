-- scroll of identify (SCR_IDENTIFY) belongs to OBJ_SCROLLS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "SCR_IDENTIFY",
    name = "scroll of identify",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- scroll of identify has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "scroll of identify",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether scroll of identify enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_VERY_COMMON",
        weight = 200,
    },
}

register.definition(categories.ITEMS, definition)

return definition

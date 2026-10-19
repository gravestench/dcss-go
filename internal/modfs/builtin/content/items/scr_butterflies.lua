-- scroll of butterflies (SCR_BUTTERFLIES) belongs to OBJ_SCROLLS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "SCR_BUTTERFLIES",
    name = "scroll of butterflies",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 27,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- scroll of butterflies has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "scroll of butterflies",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether scroll of butterflies enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_UNCOMMON",
        weight = 36,
    },
}

register.definition(categories.ITEMS, definition)

return definition

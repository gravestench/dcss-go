-- potion of brilliance (POT_BRILLIANCE) belongs to OBJ_POTIONS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "POT_BRILLIANCE",
    name = "potion of brilliance",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 4,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- potion of brilliance has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "potion of brilliance",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether potion of brilliance enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_UNCOMMON",
        weight = 67,
    },
}

register.definition(categories.ITEMS, definition)

return definition

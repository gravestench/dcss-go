-- potion of magic (POT_MAGIC) belongs to OBJ_POTIONS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "POT_MAGIC",
    name = "potion of magic",
    glyph = 33,
    class = "OBJ_POTIONS",
    class_value = 7,
    subtype_value = 20,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- potion of magic has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "potion of magic",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether potion of magic enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_RARE",
        weight = 35,
    },
}

register.definition(categories.ITEMS, definition)

return definition

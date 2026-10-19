-- scroll of fog (SCR_FOG) belongs to OBJ_SCROLLS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "SCR_FOG",
    name = "scroll of fog",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 15,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- scroll of fog has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "scroll of fog",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether scroll of fog enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        rarity = "RARITY_UNCOMMON",
        weight = 36,
    },
}

register.definition(categories.ITEMS, definition)

return definition

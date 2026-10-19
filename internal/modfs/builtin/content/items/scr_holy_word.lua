-- scroll of holy word (SCR_HOLY_WORD) belongs to OBJ_SCROLLS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "SCR_HOLY_WORD",
    name = "scroll of holy word",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 21,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- scroll of holy word has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "scroll of holy word",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode none controls whether scroll of holy word enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "none",
        rarity = "RARITY_NONE",
        weight = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition

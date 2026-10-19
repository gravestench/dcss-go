-- icy rune of Zot (RUNE_COCYTUS) belongs to OBJ_RUNES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "RUNE_COCYTUS",
    name = "icy rune of Zot",
    glyph = 125,
    class = "OBJ_RUNES",
    class_value = 15,
    subtype_value = 9,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- icy rune of Zot has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "icy rune of Zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether icy rune of Zot enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

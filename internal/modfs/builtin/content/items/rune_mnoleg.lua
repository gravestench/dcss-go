-- glowing rune of Zot (RUNE_MNOLEG) belongs to OBJ_RUNES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "RUNE_MNOLEG",
    name = "glowing rune of Zot",
    glyph = 125,
    class = "OBJ_RUNES",
    class_value = 15,
    subtype_value = 13,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- glowing rune of Zot has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "glowing rune of Zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether glowing rune of Zot enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

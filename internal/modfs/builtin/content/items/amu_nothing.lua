-- amulet of nothing (AMU_NOTHING) belongs to OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "AMU_NOTHING",
    name = "amulet of nothing",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 43,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- amulet of nothing has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "amulet of nothing",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether amulet of nothing enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

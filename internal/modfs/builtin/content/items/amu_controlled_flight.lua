-- amulet of controlled flight (AMU_CONTROLLED_FLIGHT) belongs to
-- OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "AMU_CONTROLLED_FLIGHT",
    name = "amulet of controlled flight",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 41,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- amulet of controlled flight has its display text here so identification
    -- policy can choose known or unknown names consistently.
    naming = {
        text = "amulet of controlled flight",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether amulet of controlled flight enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

-- removed rod (ROD_IGNITION) belongs to OBJ_RODS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "ROD_IGNITION",
    name = "removed rod",
    glyph = 124,
    class = "OBJ_RODS",
    class_value = 14,
    subtype_value = 2,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- removed rod has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "removed rod",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether removed rod enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

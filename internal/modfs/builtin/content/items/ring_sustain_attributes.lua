-- ring of sustain attributes (RING_SUSTAIN_ATTRIBUTES) belongs to
-- OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "RING_SUSTAIN_ATTRIBUTES",
    name = "ring of sustain attributes",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 12,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- ring of sustain attributes has its display text here so identification
    -- policy can choose known or unknown names consistently.
    naming = {
        text = "ring of sustain attributes",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether ring of sustain attributes enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition

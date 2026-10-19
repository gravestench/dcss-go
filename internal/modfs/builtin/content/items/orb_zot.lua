-- Orb of Zot (ORB_ZOT) belongs to OBJ_ORBS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "ORB_ZOT",
    name = "Orb of Zot",
    glyph = 123,
    class = "OBJ_ORBS",
    class_value = 10,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Orb of Zot has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "Orb of Zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether Orb of Zot enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

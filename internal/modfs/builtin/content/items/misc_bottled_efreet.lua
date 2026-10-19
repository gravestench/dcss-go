-- empty flask (MISC_BOTTLED_EFREET) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_BOTTLED_EFREET",
    name = "empty flask",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- empty flask has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "empty flask",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether empty flask enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

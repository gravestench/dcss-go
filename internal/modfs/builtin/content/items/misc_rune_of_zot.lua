-- obsolete rune of zot (MISC_RUNE_OF_ZOT) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_RUNE_OF_ZOT",
    name = "obsolete rune of zot",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 19,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- obsolete rune of zot has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "obsolete rune of zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether obsolete rune of zot enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

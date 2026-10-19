-- removed deck (MISC_DECK_OF_ODDITIES) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_DECK_OF_ODDITIES",
    name = "removed deck",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 25,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- removed deck has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "removed deck",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- The "removed" name is legacy catalog text, not the removed flag.
    -- Forced mode keeps this subtype out of ordinary random item rolls.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

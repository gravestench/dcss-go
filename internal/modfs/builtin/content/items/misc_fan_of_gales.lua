-- removed fan of gales (MISC_FAN_OF_GALES) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_FAN_OF_GALES",
    name = "removed fan of gales",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 1,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- removed fan of gales has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "removed fan of gales",
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

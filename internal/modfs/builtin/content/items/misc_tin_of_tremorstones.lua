-- tin of tremorstones (MISC_TIN_OF_TREMORSTONES) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_TIN_OF_TREMORSTONES",
    name = "tin of tremorstones",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 27,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- tin of tremorstones has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "tin of tremorstones",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether tin of tremorstones enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition

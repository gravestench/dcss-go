-- quad damage (MISC_QUAD_DAMAGE) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_QUAD_DAMAGE",
    name = "quad damage",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 20,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- quad damage has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "quad damage",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether quad damage enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition

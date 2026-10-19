-- phial of floods (MISC_PHIAL_OF_FLOODS) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_PHIAL_OF_FLOODS",
    name = "phial of floods",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 21,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- phial of floods has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "phial of floods",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether phial of floods enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition

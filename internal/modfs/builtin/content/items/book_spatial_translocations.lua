-- book of Spatial Translocations (BOOK_SPATIAL_TRANSLOCATIONS) belongs to
-- OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_SPATIAL_TRANSLOCATIONS",
    name = "book of Spatial Translocations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 7,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Spatial Translocations has its display text here so identification
    -- policy can choose known or unknown names consistently.
    naming = {
        text = "book of Spatial Translocations",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Spatial Translocations
    -- enters random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_BLINK,
            spells.SPELL_BECKONING,
            spells.SPELL_MANIFOLD_ASSAULT,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

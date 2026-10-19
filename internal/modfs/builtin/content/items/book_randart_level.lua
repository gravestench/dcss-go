-- book of Fixed Level (BOOK_RANDART_LEVEL) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_RANDART_LEVEL",
    name = "book of Fixed Level",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 43,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Fixed Level has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Fixed Level",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Fixed Level enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

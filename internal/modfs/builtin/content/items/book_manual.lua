-- manual (BOOK_MANUAL) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_MANUAL",
    name = "manual",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 45,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- manual has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "manual",
        kind = "manual_skill",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether manual enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

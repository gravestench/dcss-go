-- tome of obsoleteness (BOOK_BUGGY_DESTRUCTION) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "BOOK_BUGGY_DESTRUCTION",
    name = "tome of obsoleteness",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 46,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- tome of obsoleteness has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "tome of obsoleteness",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode none controls whether tome of obsoleteness enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "none",
        spells = {
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

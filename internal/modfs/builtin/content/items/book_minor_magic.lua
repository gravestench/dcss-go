-- book of Minor Magic (BOOK_MINOR_MAGIC) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_MINOR_MAGIC",
    name = "book of Minor Magic",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Minor Magic has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Minor Magic",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Minor Magic enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_MAGIC_DART,
            spells.SPELL_CALL_IMP,
            spells.SPELL_MEPHITIC_CLOUD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

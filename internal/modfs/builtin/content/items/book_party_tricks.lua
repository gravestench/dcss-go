-- book of Party Tricks (BOOK_PARTY_TRICKS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_PARTY_TRICKS",
    name = "book of Party Tricks",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 32,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Party Tricks has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Party Tricks",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Party Tricks enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_APPORTATION,
            spells.SPELL_INTOXICATE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

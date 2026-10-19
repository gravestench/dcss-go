-- book of Blasting (BOOK_BLASTING) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BLASTING",
    name = "book of Blasting",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 60,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Blasting has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Blasting",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Blasting enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FULMINANT_PRISM,
            spells.SPELL_ISKENDERUNS_MYSTIC_BLAST,
            spells.SPELL_LRD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

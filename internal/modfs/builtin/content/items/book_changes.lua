-- book of Changes (BOOK_CHANGES) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_CHANGES",
    name = "book of Changes",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 13,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Changes has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Changes",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Changes enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_BEASTLY_APPENDAGE,
            spells.SPELL_WEREBLOOD,
            spells.SPELL_SPIDER_FORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

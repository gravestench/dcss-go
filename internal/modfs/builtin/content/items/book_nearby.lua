-- Inescapable Atlas (BOOK_NEARBY) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_NEARBY",
    name = "Inescapable Atlas",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 62,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Inescapable Atlas has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "Inescapable Atlas",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Inescapable Atlas enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_BLINK,
            spells.SPELL_MANIFOLD_ASSAULT,
            spells.SPELL_STORM_FORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

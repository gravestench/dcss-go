-- book of Air (BOOK_AIR) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_AIR",
    name = "book of Air",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 20,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Air has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Air",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Air enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SHOCK,
            spells.SPELL_SWIFTNESS,
            spells.SPELL_AIRSTRIKE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

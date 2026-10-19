-- book of Touch (BOOK_TOUCH) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TOUCH",
    name = "book of Touch",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 70,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Touch has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Touch",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Touch enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_DISCHARGE,
            spells.SPELL_STICKY_FLAME,
            spells.SPELL_DISPEL_UNDEAD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

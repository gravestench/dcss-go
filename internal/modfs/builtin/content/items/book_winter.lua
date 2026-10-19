-- book of Winter (BOOK_WINTER) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_WINTER",
    name = "book of Winter",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 48,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Winter has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Winter",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Winter enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_OZOCUBUS_ARMOUR,
            spells.SPELL_ENGLACIATION,
            spells.SPELL_SIMULACRUM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

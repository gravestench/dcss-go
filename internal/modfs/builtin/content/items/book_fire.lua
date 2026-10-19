-- book of Fire (BOOK_FIRE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_FIRE",
    name = "book of Fire",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 5,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Fire has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Fire",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Fire enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FIREBALL,
            spells.SPELL_STARBURST,
            spells.SPELL_IGNITION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

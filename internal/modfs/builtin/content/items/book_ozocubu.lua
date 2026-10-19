-- Ozocubu's Autobiography (BOOK_OZOCUBU) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_OZOCUBU",
    name = "Ozocubu's Autobiography",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 57,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Ozocubu's Autobiography has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "Ozocubu's Autobiography",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Ozocubu's Autobiography enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_OZOCUBUS_ARMOUR,
            spells.SPELL_OZOCUBUS_REFRIGERATION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

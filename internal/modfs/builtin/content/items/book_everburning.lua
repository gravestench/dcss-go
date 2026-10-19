-- Everburning Encyclopedia (BOOK_EVERBURNING) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_EVERBURNING",
    name = "Everburning Encyclopedia",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 55,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Everburning Encyclopedia has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "Everburning Encyclopedia",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Everburning Encyclopedia enters
    -- random item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_CONJURE_FLAME,
            spells.SPELL_IGNITE_POISON,
            spells.SPELL_STICKY_FLAME,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

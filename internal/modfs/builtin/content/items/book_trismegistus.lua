-- Trismegistus Codex (BOOK_TRISMEGISTUS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TRISMEGISTUS",
    name = "Trismegistus Codex",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 75,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Trismegistus Codex has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "Trismegistus Codex",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Trismegistus Codex enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_IGNITE_POISON,
            spells.SPELL_MEPHITIC_CLOUD,
            spells.SPELL_FREEZING_CLOUD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

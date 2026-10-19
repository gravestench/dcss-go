-- Fen Folio (BOOK_FEN) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_FEN",
    name = "Fen Folio",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 15,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Fen Folio has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "Fen Folio",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Fen Folio enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_FOREST,
            spells.SPELL_NOXIOUS_BOG,
            spells.SPELL_SUMMON_HYDRA,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

-- Akashic Record (BOOK_AKASHIC_RECORD) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_AKASHIC_RECORD",
    name = "Akashic Record",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 33,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Akashic Record has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "Akashic Record",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode none controls whether Akashic Record enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_DISPERSAL,
            spells.SPELL_MALIGN_GATEWAY,
            spells.SPELL_DISJUNCTION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

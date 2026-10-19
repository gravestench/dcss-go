-- book of Pain (BOOK_PAIN) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_PAIN",
    name = "book of Pain",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 51,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Pain has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Pain",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode none controls whether book of Pain enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_NECROTISE,
            spells.SPELL_AGONY,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

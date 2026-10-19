-- book of the Senses (BOOK_SENSES) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_SENSES",
    name = "book of the Senses",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 58,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Senses has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of the Senses",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Senses enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_DAZZLING_FLASH,
            spells.SPELL_AGONY,
            spells.SPELL_SILENCE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

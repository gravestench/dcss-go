-- book of Spectacle (BOOK_SPECTACLE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_SPECTACLE",
    name = "book of Spectacle",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 47,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Spectacle has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Spectacle",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Spectacle enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_DAZZLING_FLASH,
            spells.SPELL_ISKENDERUNS_MYSTIC_BLAST,
            spells.SPELL_STARBURST,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

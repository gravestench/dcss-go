-- book of Storms (BOOK_STORMS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_STORMS",
    name = "book of Storms",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 64,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Storms has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Storms",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Storms enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_AIRSTRIKE,
            spells.SPELL_SUMMON_LIGHTNING_SPIRE,
            spells.SPELL_LIGHTNING_BOLT,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

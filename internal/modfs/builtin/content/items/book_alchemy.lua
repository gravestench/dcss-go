-- book of Alchemy (BOOK_ALCHEMY) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_ALCHEMY",
    name = "book of Alchemy",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 38,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Alchemy has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Alchemy",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Alchemy enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUBLIMATION_OF_BLOOD,
            spells.SPELL_PETRIFY,
            spells.SPELL_IRRADIATE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

-- book of the Tundra (BOOK_TUNDRA) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TUNDRA",
    name = "book of the Tundra",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 63,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Tundra has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of the Tundra",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Tundra enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_HAILSTORM,
            spells.SPELL_ICE_FORM,
            spells.SPELL_SIMULACRUM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

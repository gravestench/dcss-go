-- book of Ice (BOOK_ICE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_ICE",
    name = "book of Ice",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Ice has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Ice",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Ice enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FREEZING_CLOUD,
            spells.SPELL_SIMULACRUM,
            spells.SPELL_POLAR_VORTEX,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

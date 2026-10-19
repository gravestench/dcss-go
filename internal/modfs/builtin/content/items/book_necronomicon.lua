-- Necronomicon (BOOK_NECRONOMICON) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_NECRONOMICON",
    name = "Necronomicon",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 42,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Necronomicon has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "Necronomicon",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Necronomicon enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_BORGNJORS_REVIVIFICATION,
            spells.SPELL_NECROMUTATION,
            spells.SPELL_DEATHS_DOOR,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

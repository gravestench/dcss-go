-- book of the Earth (BOOK_EARTH) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_EARTH",
    name = "book of the Earth",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 56,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Earth has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of the Earth",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Earth enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_LEDAS_LIQUEFACTION,
            spells.SPELL_LRD,
            spells.SPELL_STATUE_FORM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

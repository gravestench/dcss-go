-- book of Iron (BOOK_IRON) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_IRON",
    name = "book of Iron",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 61,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Iron has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Iron",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Iron enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_ANIMATE_ARMOUR,
            spells.SPELL_BLADE_HANDS,
            spells.SPELL_IRON_SHOT,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

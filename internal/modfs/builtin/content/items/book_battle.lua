-- book of Battle (BOOK_BATTLE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BATTLE",
    name = "book of Battle",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 26,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Battle has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Battle",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode none controls whether book of Battle enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_WEREBLOOD,
            spells.SPELL_OZOCUBUS_ARMOUR,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition

-- book of Rime (BOOK_RIME) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_RIME",
    name = "book of Rime",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 54,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Rime has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Rime",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Rime enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FROZEN_RAMPARTS,
            spells.SPELL_ICE_FORM,
            spells.SPELL_SUMMON_ICE_BEAST,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
